# External data source to get the Atlantis ECS task public IP
data "external" "atlantis_public_ip" {
  program = ["python3", "${path.module}/scripts/get_atlantis_ip.py"]
  query = {
    cluster = aws_ecs_cluster.atlantis_cluster.id
    service = aws_ecs_service.atlantis_service.name
  }
}

output "atlantis_public_ip" {
  description = "Public IP of the Atlantis ECS task"
  value       = data.external.atlantis_public_ip.result.public_ip
}
