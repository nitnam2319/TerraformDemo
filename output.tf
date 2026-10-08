output "linux-public-ip"{
    value = aws_instance.LinuxSRV01.public_ip
    
}