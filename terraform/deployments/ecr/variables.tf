variable "puller_arns" {
  type        = list(string)
  description = "List of IAM principals who should be authorised to pull from this registry."
}

variable "emails" {
  type    = list(string)
  default = [] # TODO: Set emails in tfvars.

}

