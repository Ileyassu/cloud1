output "public_ips" {
  value = aws_eip.web[*].public_ip
}

# Generate the Ansible inventory as a side effect of apply.
# No more copy-pasting IPs; no more stale inventory files.
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
    [web]
    %{ for ip in aws_eip.web[*].public_ip ~}
    ${ip}
    %{ endfor ~}

    [web:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=~/.ssh/cloud1
  EOT
}