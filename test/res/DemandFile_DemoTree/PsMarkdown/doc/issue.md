# issue

- [x] 2023_11_09_230331
  - where
    - ``PsMarkdown#Link#Get-MarkdownLink``
  - actual

    ```text
    typename F
    F(T)
    F(T)
    int
    int
    int
    decltype(add)(int, int)
    int
    typename U, typename F

    ...

    kbd
    kbd
    kbd
    kbd
    kbd
    kbd
    ```

- [x] 2023_11_14_234154
  - where
    - ``PsMarkdown#ClipImage#Save-ClipboardToImageFormat``
  - howto
    - <kb>Alt</kb> + <kb>PrtSc</kb>

    - ```powershell
      Save-ClipboardToImageFormat `
          -BasePath . `
          -FolderName __temp `
          -FileName sus `
          -FileExtension png
      ```

  - actual

    ```
    Save-ClipboardToImageFormat : No file found at System.Drawing.Bitmap
    At line:1 char:1
    + Save-ClipboardToImageFormat -BasePath . -FolderName __temp -FileName  ...
    + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorExcept
       ion
        + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException
       ,Save-ClipboardToImageFormat


    Success Path MarkdownString Format
    ------- ---- -------------- ------
       True                     Image
    ```

- [x] 2023_08_09_010903

  - where
    - ``PsMarkdown#Link#Move-MarkdownItem``
  - actual
    ```
    C:\note [master ≡]> Move-MarkdownItem -Source .\watch_-_2023_02_07.md -Destination .\watch\__COMPLETE\
    The variable '$matchInfo' cannot be retrieved because it has not been set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:489 char:44
    +                             'LineNumber' = $matchInfo.LineNumber
    +                                            ~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (matchInfo:String) [], RuntimeException
        + FullyQualifiedErrorId : VariableIsUndefined
    
    The property 'BackReferences' cannot be found on this object. Verify that the property exists and can
    be set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:536 char:17
    + ...              $moveItem.BackReferences = $cats.Keys | sort | foreach {
    +                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
        + FullyQualifiedErrorId : PropertyNotFound
    
    The property 'ChangeLinks' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:543 char:17
    +                 $moveItem.ChangeLinks += @(
    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    
    The property 'Content' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:607 char:9
    +         $moveLinkInfo.Content | Out-File $Destination -Force
    +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    
    The property 'Content' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:609 char:13
    +         if (diff ($moveLinkInfo.Content) (cat $Destination)) {
    +             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    
    The property 'BackReferences' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:616 char:30
    +         foreach ($backRef in $moveLinkInfo.BackReferences) {
    +                              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    ```

- [x] 2023_05_02_203733

  - where
    - ``PsMarkdown#Link#Move-MarkdownItem``
  - actual

    ```
    C:\note [master ≡ +4 ~4 -0 !]> Move-MarkdownItem .\pool_-_2023_01_26.md C:\note\d
    rawboard
    The variable '$matchInfo' cannot be retrieved because it has not been set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:480 char:44
    +                             'LineNumber' = $matchInfo.LineNumber
    +                                            ~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (matchInfo:String) [], RuntimeE
       xception
        + FullyQualifiedErrorId : VariableIsUndefined

    The property 'BackReferences' cannot be found on this object. Verify that the
    property exists and can be set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:527 char:17
    + ...              $moveItem.BackReferences = $cats.Keys | sort | foreach {
    +                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
        + FullyQualifiedErrorId : PropertyNotFound

    The property 'ChangeLinks' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:534 char:17
    +                 $moveItem.ChangeLinks += @(
    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

        Directory: C:\note\drawboard

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----          5/2/2023   8:34 PM                res
    The property 'Content' cannot be found on this object. Verify that the property
    exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:598 char:9
    +         $moveLinkInfo.Content | Out-File $Destination -Force
    +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    The property 'Content' cannot be found on this object. Verify that the property
    exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:600 char:13
    +         if (diff ($moveLinkInfo.Content) (cat $Destination)) {
    +             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    The property 'BackReferences' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:607 char:30
    +         foreach ($backRef in $moveLinkInfo.BackReferences) {
    +                              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    ```

- [x] 2023_04_09_151015
  - where
    - ``PsMarkdown#Link#Move-MarkdownItem``
  - actual

    ```
    C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTool\note [master ≡]> Move-MarkdownItem .\todo_-_2022_03_23.md ..\doc\
    The variable '$matchInfo' cannot be retrieved because it has not been set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:480 char:44
    +                             'LineNumber' = $matchInfo.LineNumber
    +                                            ~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (matchInfo:String) [], RuntimeE
       xception
        + FullyQualifiedErrorId : VariableIsUndefined

    The property 'BackReferences' cannot be found on this object. Verify that the
    property exists and can be set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:527 char:17
    + ...              $moveItem.BackReferences = $cats.Keys | sort | foreach {
    +                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
        + FullyQualifiedErrorId : PropertyNotFound

    The property 'ChangeLinks' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:534 char:17
    +                 $moveItem.ChangeLinks += @(
    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

        Directory:
        C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTool\doc

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----          4/9/2023   3:07 PM                res
    The property 'Content' cannot be found on this object. Verify that the property
    exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:598 char:9
    +         $moveLinkInfo.Content | Out-File $Destination -Force
    +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    The property 'Content' cannot be found on this object. Verify that the property
    exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:600 char:13
    +         if (diff ($moveLinkInfo.Content) (cat $Destination)) {
    +             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    The property 'BackReferences' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script
    \Link.ps1:607 char:30
    +         foreach ($backRef in $moveLinkInfo.BackReferences) {
    +                              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTool\note [master ≡ +2 ~0 -3 !]> dir

        Directory:
        C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTool\note

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    da---l          4/9/2023   3:07 PM                res

    C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTool\note [master ≡ +2 ~0 -3 !]>
    ```

- [x] 2023_09_07_201444

  - where
    - ``PsMarkdown#Link#Get-MarkdownLinkSparse``
  - actual
    ```
    C:\note [master ≡ +0 ~3 -0 !]> dir *.md -Recurse | sls cbc | mdlink
    F, spoke over intercom
    ```

- [x] 2023_09_07_210457

  - where
    - ``PsMarkdown#Link#Get-MarkdownLinkSparse``
  - howto
    - ``cd \note; dir *.md -Recurse | sls cbc | mdlink -TestWebLink``
  - actual
    - takes a while to halt

- [x] 2023_09_06_003943

  - where
    - ``PsMarkdown#Link#Get-MarkdownLinkSparse``
  - actual
    ```
    C:\note\todo [master ≡ +2 ~3 -0 !]> dir *.md | mdlink
    Index was outside the bounds of the array.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsMarkdown\script\Link.ps1:41 char:13
    +             @($links)[0]
    +             ~~~~~~~~~~~~
        + CategoryInfo          : OperationStopped: (:) [], IndexOutOfRangeException
        + FullyQualifiedErrorId : System.IndexOutOfRangeException
    ```

---
[← Go Back](../readme.md)
