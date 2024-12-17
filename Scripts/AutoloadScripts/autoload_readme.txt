Settings: User-defined settings and global callables like play_audio(), swizzle() are in settings, 
because that's where the variables those functions depend on are declared.

Data: Contains game content data and enums and paths to their resources. Ships, weapons, fighters, and so on.

Game State: Contains save/load functions and runtime game data that is needed to save.
