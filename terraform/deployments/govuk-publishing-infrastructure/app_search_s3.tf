# TODO: instead of granting write access to nodes, use IRSA (IAM Roles for
# Service Accounts aka pod identity) so that only search-api containers can write.
resource "aws_iam_role_policy_attachment" "search_relevancy_s3_eks_policy_attachment" {
  role       = data.terraform_remote_state.cluster_infrastructure.outputs.worker_iam_role_name
  policy_arn = data.terraform_remote_state.app_search.outputs.search_relevancy_s3_policy_arn
}

resource "aws_iam_role_policy_attachment" "sitemaps_s3_eks_policy_attachment" {
  role       = data.terraform_remote_state.cluster_infrastructure.outputs.worker_iam_role_name
  policy_arn = data.terraform_remote_state.app_search.outputs.sitemaps_s3_policy_arn
}
