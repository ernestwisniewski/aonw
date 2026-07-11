/// Maximum number of authoritative multiplayer events returned in one page.
///
/// Both the server query and client continuation rule must use this protocol
/// value; otherwise a smaller server page can look like the end of history.
const multiplayerEventPageSize = 256;
