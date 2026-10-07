# note

## MdPath

``Get-MdPath``

- has a ``Recurse`` flag, but when not set, subfolders are not discoverable by default (such as "minecraft")

  ```powershell
  pathto code minecraft, insomnia -Mode And
  ```

  ```text
  ```

- code blocks are not discoverable if
  - searched using a paragraph that is not directly above them
    - case 1: under a ``tag``

      ```markdown
      # howto: Minecraft

      ## 2026-10-06: troubleshoot

      As of Minecraft Java 1.21.11, Mojang changed the name of ``doInsomnia`` to ``spawn_phantoms``.

      - tag: #gamerule #insomnia

      ` ` `text
      /gamerule spawn_phantoms false
      ` ` `

      ` ` `text
      /gamerule minecraft:spawn_phantoms false
      ` ` `
      ```

      ```powershell
      pathto code minecraft, insomnia -Mode And | foreach Command
      ```

      ```text
      ```

    - case 2: under another code block

      ```markdown
      # howto: Minecraft

      ## 2026-10-06: troubleshoot

      - tag: #gamerule #insomnia

      As of Minecraft Java 1.21.11, Mojang changed the name of ``doInsomnia`` to ``spawn_phantoms``.

      ` ` `text
      /gamerule spawn_phantoms false
      ` ` `

      ` ` `text
      /gamerule minecraft:spawn_phantoms false
      ` ` `
      ```

      ```powershell
      pathto code minecraft, insomnia -Mode And | foreach Command
      ```

      ```text
      /gamerule spawn_phantoms false
      ```

  - the exact paragraph is reused

    ```markdown
    # howto: Minecraft

    ## 2026-10-06: troubleshoot

    - tag: #gamerule #insomnia

    As of Minecraft Java 1.21.11, Mojang changed the name of ``doInsomnia`` to ``spawn_phantoms``.

    ` ` `text
    /gamerule spawn_phantoms false
    ` ` `

    As of Minecraft Java 1.21.11, Mojang changed the name of ``doInsomnia`` to ``spawn_phantoms``.

    ` ` `text
    /gamerule minecraft:spawn_phantoms false
    ` ` `
    ```

    ```powershell
    pathto code minecraft, insomnia -Mode And | foreach Command
    ```

    ```text
    /gamerule spawn_phantoms false
    ```

---

[← Go Back](../readme.md)

