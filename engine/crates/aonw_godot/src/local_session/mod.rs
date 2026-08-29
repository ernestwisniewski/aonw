use std::collections::{BTreeMap, BTreeSet};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::thread::{self, JoinHandle};

use aonw_ai::StrategicPlanner;
use aonw_contracts::client::CLIENT_API_VERSION;
use aonw_local_runtime::{ClientProtocol, LocalRuntime};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

const BUILD_IDENTITY: &str = match option_env!("AONW_GODOT_BUILD_IDENTITY") {
    Some(identity) => identity,
    None => "aonw_godot/development",
};
const MAX_OUTSTANDING_JOBS: usize = 64;

#[derive(GodotClass)]
#[class(tool, base=RefCounted)]
struct AonwLocalSession {
    worker: SessionWorker,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwLocalSession {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            worker: SessionWorker::new(),
            base,
        }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value, clippy::unused_self)]
impl AonwLocalSession {
    #[func]
    fn client_api_version(&self) -> i64 {
        i64::from(CLIENT_API_VERSION)
    }

    #[func]
    fn build_identity(&self) -> GString {
        GString::from(adapter_build_identity())
    }

    #[func]
    fn request_json(&mut self, request_json: GString) -> GString {
        let response = self.worker.request_sync(request_json.to_string());
        GString::from(response.as_str())
    }

    /// Queues one request on the serial engine worker and returns its job id.
    #[func]
    fn request_json_async(&mut self, request_json: GString) -> i64 {
        self.worker
            .enqueue(request_json.to_string())
            .and_then(|job_id| i64::try_from(job_id).ok())
            .unwrap_or(-1)
    }

    /// Returns whether a queued response can be collected without blocking.
    #[func]
    fn is_response_ready(&mut self, job_id: i64) -> bool {
        u64::try_from(job_id)
            .ok()
            .is_some_and(|job_id| self.worker.is_ready(job_id))
    }

    /// Collects one ready response, or an empty string while it is pending.
    #[func]
    fn poll_response_json(&mut self, job_id: i64) -> GString {
        let response = u64::try_from(job_id)
            .ok()
            .and_then(|job_id| self.worker.poll(job_id))
            .unwrap_or_default();
        GString::from(response.as_str())
    }
}

fn dispatch_json(runtime: &mut LocalRuntime, input: &str) -> String {
    let mut ai_driver = StrategicPlanner;
    if let Ok(response) = catch_unwind(AssertUnwindSafe(|| {
        ClientProtocol::dispatch_json_with_ai(runtime, input, &mut ai_driver)
    })) {
        response
    } else {
        runtime.poison();
        ClientProtocol::failure_json("native_panic", "native request failed; session invalidated")
    }
}

struct WorkerRequest {
    job_id: u64,
    input: String,
}

struct WorkerResponse {
    job_id: u64,
    output: String,
}

struct SessionWorker {
    requests: Option<SyncSender<WorkerRequest>>,
    responses: Receiver<WorkerResponse>,
    pending: BTreeMap<u64, String>,
    outstanding: BTreeSet<u64>,
    next_job_id: u64,
    cancelled: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl SessionWorker {
    fn new() -> Self {
        let (request_sender, request_receiver) =
            mpsc::sync_channel::<WorkerRequest>(MAX_OUTSTANDING_JOBS);
        let (response_sender, response_receiver) = mpsc::channel::<WorkerResponse>();
        let cancelled = Arc::new(AtomicBool::new(false));
        let worker_cancelled = Arc::clone(&cancelled);
        let thread = thread::spawn(move || {
            let mut runtime = LocalRuntime::default();
            while let Ok(request) = request_receiver.recv() {
                if worker_cancelled.load(Ordering::Acquire) {
                    break;
                }
                let output = dispatch_json(&mut runtime, &request.input);
                if worker_cancelled.load(Ordering::Acquire) {
                    break;
                }
                if response_sender
                    .send(WorkerResponse {
                        job_id: request.job_id,
                        output,
                    })
                    .is_err()
                {
                    break;
                }
            }
        });
        Self {
            requests: Some(request_sender),
            responses: response_receiver,
            pending: BTreeMap::new(),
            outstanding: BTreeSet::new(),
            next_job_id: 1,
            cancelled,
            thread: Some(thread),
        }
    }

    fn enqueue(&mut self, input: String) -> Option<u64> {
        if self.outstanding.len() >= MAX_OUTSTANDING_JOBS {
            return None;
        }
        let job_id = self.next_job_id;
        self.next_job_id = self.next_job_id.checked_add(1)?;
        self.requests
            .as_ref()?
            .try_send(WorkerRequest { job_id, input })
            .ok()?;
        self.outstanding.insert(job_id);
        Some(job_id)
    }

    fn request_sync(&mut self, input: String) -> String {
        let Some(job_id) = self.enqueue(input) else {
            return ClientProtocol::failure_json(
                "engine_worker_unavailable",
                "engine worker is unavailable",
            );
        };
        loop {
            if let Some(output) = self.pending.remove(&job_id) {
                self.outstanding.remove(&job_id);
                return output;
            }
            match self.responses.recv() {
                Ok(response) if response.job_id == job_id => {
                    self.outstanding.remove(&job_id);
                    return response.output;
                }
                Ok(response) => {
                    self.pending.insert(response.job_id, response.output);
                }
                Err(_) => {
                    self.outstanding.clear();
                    return ClientProtocol::failure_json(
                        "engine_worker_unavailable",
                        "engine worker stopped before returning a response",
                    );
                }
            }
        }
    }

    fn is_ready(&mut self, job_id: u64) -> bool {
        self.drain();
        self.pending.contains_key(&job_id)
    }

    fn poll(&mut self, job_id: u64) -> Option<String> {
        self.drain();
        let response = self.pending.remove(&job_id);
        if response.is_some() {
            self.outstanding.remove(&job_id);
        }
        response
    }

    fn drain(&mut self) {
        while let Ok(response) = self.responses.try_recv() {
            self.pending.insert(response.job_id, response.output);
        }
    }
}

impl Drop for SessionWorker {
    fn drop(&mut self) {
        self.cancelled.store(true, Ordering::Release);
        self.requests.take();
        // Dropping a running handle detaches it. The cancellation flag stops queued work,
        // while the current bounded request may finish without blocking Godot's main thread.
        if let Some(thread) = self.thread.take()
            && thread.is_finished()
        {
            let _ = thread.join();
        }
    }
}

fn adapter_build_identity() -> &'static str {
    BUILD_IDENTITY
}

#[cfg(test)]
mod tests;
