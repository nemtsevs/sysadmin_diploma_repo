virtual_machines = {
  "vm1" = {
    vm_name        = "cloud-vm-01"          # Имя ВМ
    vm_desc        = "1-я vm"               # Описание
    vm_platform    = "standard-v3"          # Intel Ice Lake
    vm_cpu         = 2                      # Кол-во ядер процессора
    core_fraction  = 20                     # Гарантированная доля vCPU
    #is_preemptible = true                   # Прерываемая
    ram            = 2                      # Оперативная память в ГБ
    disk           = 20                     # Объём диска в ГБ
    disk_name      = "cloud-disk-01"        # Название диска
    template       = "fd80jhic7e80h9s58v62" # ID образа ОС для использования
  },
  "vm2" = {
    vm_name        = "cloud-vm-02"          # Имя ВМ
    vm_desc        = "2-я vm"               # Описание
    vm_platform    = "standard-v3"          # Intel Ice Lake
    vm_cpu         = 2                      # Кол-во ядер процессора
    core_fraction  = 20                     # Гарантированная доля vCPU
    #is_preemptible = true                   # Прерываемая
    ram            = 2                      # Оперативная память в ГБ
    disk           = 20                     # Объём диска в ГБ
    disk_name      = "cloud-disk-02"        # Название диска
    template       = "fd80jhic7e80h9s58v62" # ID образа ОС для использования
  },
  "vm3" = {
    vm_name        = "cloud-vm-03"          # Имя ВМ
    vm_desc        = "3-я vm"               # Описание
    vm_platform    = "standard-v3"          # Intel Ice Lake
    vm_cpu         = 2                      # Кол-во ядер процессора
    core_fraction  = 20                     # Гарантированная доля vCPU
    #is_preemptible = true                   # Прерываемая
    ram            = 2                      # Оперативная память в ГБ
    disk           = 20                     # Объём диска в ГБ
    disk_name      = "cloud-disk-03"        # Название диска
    template       = "fd80jhic7e80h9s58v62" # ID образа ОС для использования
  }
}

s3bucket = {
  name             = "s3bucket-s20691161-1" # Имя бакета
  max_size         = 20 * 1024 * 1024       # Макс. объём бакета
}
