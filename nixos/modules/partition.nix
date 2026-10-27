{ ... }:
{
  disko.devices.disk.main = {
    type   = "disk";
    device = "/dev/nvme0n1";

    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size     = "1G";
          type     = "EF00";
          content = {
            type         = "filesystem";
            format       = "vfat";
            mountpoint   = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          priority = 2;
          size     = "800G";
          content = {
            type                   = "luks";
            name                   = "cryptroot"; # no passwordFile, so it prompts
            settings.allowDiscards = true;        # SSD
            settings.crypttabExtraOpts = [ "password-echo=yes" ];
            content = {
              type       = "filesystem";
              format     = "ext4";
              mountpoint = "/";
            };
          };
        };

        swap = {
          priority = 3;
          size     = "20G";
          content = {
            type             = "swap";
            randomEncryption = true; # hibernate is impossible
          };
        };

        # no 100% partition, so the rest stays unallocated
      };
    };
  };
}
