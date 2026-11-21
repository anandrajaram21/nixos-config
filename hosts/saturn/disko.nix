# Declarative layout for the NVMe SSD. Running disko against this file ERASES the disk.
# The NTFS data HDD is deliberately not listed here; it's mounted in configuration.nix.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-INTEL_SSDPEKKW256G8_BTHH82210B6Y256B";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
