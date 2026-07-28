import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

int targetMethodInvocationCount(
  AstNode node,
  String targetName,
  String methodName,
) {
  final collector = _TargetMethodInvocationCollector(targetName, methodName);
  node.accept(collector);
  return collector.count;
}

final class _TargetMethodInvocationCollector extends RecursiveAstVisitor<void> {
  _TargetMethodInvocationCollector(this.targetName, this.methodName);

  final String targetName;
  final String methodName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier &&
        target.name == targetName &&
        node.methodName.name == methodName) {
      count += 1;
    }
    super.visitMethodInvocation(node);
  }
}
