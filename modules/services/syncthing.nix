{}:
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    # Optional: GUI credentials (can be set in the browser instead)
    guiAddress = "0.0.0.0:8384";
    settings.gui = {
      user = "root";
      password = "root";
    };
  };
  # services.syncthing = {
  #   enable = true;
  #   openDefaultPorts = true;
  #   guiAddress = "0.0.0.0:8384";
  #   key = "/home/hardclip/syncthing-config/key.pem";
  #   cert = "/home/hardclip/syncthing-config/cert.pem";
  #   settings = {
  #     gui = {
  #       user = "root";
  #       password = "root";
  #     };
  #     devices = {
  #       "homeserver" = { id = "2YVBMXR-4IR6GH5-ZZBKLPI-5HKLGVM-3Y4BXBU-JIYOGK2-5MUVF54-OQSHSQD"; };
  #       "testLaptop" = { id = "5H2SKL3-PKOQENS-WVXICKJ-I7L5BTC-P4CHUGS-Y2SEG6Y-H2E63VW-JTOP4A6"; };
  #     };
  #     folders = {
  #       "Obsidian" = {
  #         path = "/home/hardclip/Obsidian";
  #         devices = [
  #           # We trust this device to have access
  #           # to the decrypted contents of this folder.
  #           "homeserver"
  #           "testLaptop"
  #         ];
  #       };
  #     };
  #   };
  # };
}