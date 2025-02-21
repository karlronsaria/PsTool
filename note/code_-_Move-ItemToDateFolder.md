```
def CopyFilesToBackup -> str[]
        in: Path -> str
        in: Dir -> str
        in: Force -> flag
        in: WhatIf -> flag

    if not Exist(Dir)
        yield mkdir(Dir, force: Force, what_if: WhatIf)

    for each file in ls(Path)
        yield copy(
            file.FullName,
            destination: "{Dir}/{file.Name}",
            force: Force,
            what_if: WhatIf
        )

def MoveFilesToDatedFolders -> str[]
        in: Path -> str

        in: GroupBy -> str in [
            "CreationTime",
            "LastAccessTime",
            "LastWriteTime"
        ] <- "CreationTime"

        in: Force -> flag
        in: WhatIf -> flag

    Path <- TrimEnd(Path, "\")

    for each file in ls(Path)
        date <- file."{GroupBy}"
        subdir <- FormatDate(date, "yyyy-MM-dd")

        if not Exist("{Path}/{subdir}")
            yield mkdir("{Path}/{subdir}", force: Force, what_if: WhatIf)

        dest <- "{Path}/{subdir}/{file.Name}"
        properties <- GetDateTimeStamps(file)

        yield move(file.FullName, destination: dest, force: Force, what_if: WhatIf)

        item <- GetFileInfo(dest)

        # Rewrite item's date information with previous date information
        for key, value in properties
            item.key <- value

def Main -> str[]
        in: Path -> str

        in: GroupBy -> str in [
            "CreationTime",
            "LastAccessTime",
            "LastWriteTime"
        ] <- "CreationTime"

        in: Backup -> flag
        in: Force -> flag
        in: WhatIf -> flag

    if not Path
        Path <- GetCurrentWorkingDirectory().FullName

    backup_dir <- "{Path}/temp"
    backup_dir <- backup_dir + "_" + (GetDate(format: "yyyy-MM-dd-HHmmss"))

    if Backup
        yield CopyFilesToBackup(
            Path: Path,
            Dir: backup_dir,
            Force: Force,
            WhatIf: WhatIf
        )

    yield MoveFilesToDatedFolders(
        Path: Path,
        GroupBy: GroupBy,
        Force: Force,
        WhatIf: WhatIf
    )
```
