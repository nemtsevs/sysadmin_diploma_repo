resource "yandex_compute_disk" "boot-disk" {
  for_each = var.virtual_machines
  name     = each.value["disk_name"]
  type     = "network-hdd"
  zone     = "ru-central1-b"
  size     = each.value["disk"]
  image_id = each.value["template"]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
name = "subnet1"
zone = "ru-central1-b"
network_id = yandex_vpc_network.network-1.id
v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "virtual_machine" {
  for_each        = var.virtual_machines
  name = each.value["vm_name"]
  platform_id = each.value["vm_platform"]

  resources {
    cores  = each.value["vm_cpu"]
    memory = each.value["ram"]
    core_fraction = each.value["core_fraction"]
  }

  scheduling_policy {
    preemptible = each.value["is_preemptible"]
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk[each.key].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "s20691161:${file("~/.ssh/id_ed25519.pub")}"
    user-data = <<-EOF
      #cloud-config
      users:
        - name: s20691161
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
      EOF
  }
}

resource "yandex_storage_bucket" "ice_bucket" {
  bucket        = var.s3bucket["name"]
  max_size      = var.s3bucket["max_size"]

  grant {
    id          = var.yc_service_account_id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  access_key    = var.yc_access_key_id
  secret_key    = var.yc_secret_access_key
}
