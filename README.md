# nvim-based-checklist
This is a text based check list maker/edditor, for making fast and quick checklists or todo lists. Nececerry shortcuts added so that your hand never has to leave the keyboard!

Im runing arch with hyprland (btw). Here is my setup:
in hyprland.conf: 

  windowrulev2 = float, title:^(toDo)$
  windowrulev2 = size 30% auto, title:^(toDo)$
  windowrulev2 = opacity 0.9, title:^(toDo)$
  bind = $mainMod, T, exec, ghostty --title=toDo -e ./DIRECTORY-TO-THIS-CLONE/interactive-todo-tui.sh
ths runs the program with when SUPER and T is pressed and executes the file (dont forget to "chmod +x" your file) in a floting window
