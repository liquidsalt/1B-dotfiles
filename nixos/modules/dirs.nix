{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.xdg-user-dirs
  ];

  environment.etc."xdg/user-dirs.defaults".text = ''
    DOWNLOAD=downloads
    DOCUMENTS=documents
    PICTURES=media/images
    VIDEOS=media/video
    MUSIC=media/music
  '';

  systemd.tmpfiles.rules = [
    "d /home/commander/downloads 0755 commander users -"

    "d /home/commander/documents 0755 commander users -"
    "d /home/commander/documents/notes 0755 commander users -"
    "d /home/commander/documents/gov 0755 commander users -"
    "d /home/commander/documents/finance 0755 commander users -"
    "d /home/commander/documents/school 0755 commander users -"
    "d /home/commander/documents/work 0755 commander users -"

    "d /home/commander/media 0755 commander users -"
    "d /home/commander/media/wallpapers 0755 commander users -"
    "d /home/commander/media/images 0755 commander users -"
    "d /home/commander/media/video 0755 commander users -"
    "d /home/commander/media/music 0755 commander users -"
    "d /home/commander/media/games 0755 commander users -"

    "d /home/commander/projects 0755 commander users -"
    "d /home/commander/projects/dev 0755 commander users -"
    "d /home/commander/projects/dev/templates 0755 commander users -"
    "d /home/commander/projects/dev/ai-generated 0755 commander users -"
    "d /home/commander/projects/art 0755 commander users -"

    "d /home/commander/.config/scripts 0755 commander users -"
  ];
}
