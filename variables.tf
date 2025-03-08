variable "atlantis_gh_user" {
  description = "GitHub username for Atlantis"
  type        = string
}

variable "atlantis_gh_token" {
  description = "GitHub Personal Access Token for Atlantis"
  type        = string
  sensitive   = true
}

variable "atlantis_repo_allowlist" {
  description = "GitHub repository allowlist for Atlantis"
  type        = string
}
