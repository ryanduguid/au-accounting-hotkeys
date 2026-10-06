# Sources and related projects

The sources below informed the command library. They were inspected on 6 October 2026. Project licences were checked through GitHub's repository metadata; no source code from these projects was copied into this repository.

## Similar projects

| Project | Inspected capability | Use in this library | Licence |
| --- | --- | --- | --- |
| [Lintalist](https://github.com/lintalist/lintalist) | Searches bundles and previews selected snippets | Search and preview are useful for a growing accounting command list. Its script and plug-in execution features are outside this library's scope. | GPL-2.0 |
| [SendTextZ](https://github.com/bceenaeiklmr/SendText) | Keeps editable snippets and categories in a separate file | Plain text snippet files let accountants customise wording without editing AutoHotkey code. | MIT |
| [ClipStepper](https://github.com/bceenaeiklmr/ClipStepper) | Loads clipboard tables on request and navigates cells | Clipboard input should require a separate user action. Bulk cell entry is a separate workflow. | MIT |
| [UIA-v2](https://github.com/Descolada/UIA-v2) | Provides Windows UI Automation | An option for future application-specific automation, if that work has a concrete target and tests. Native controls are sufficient for the current picker. | MIT |
| [ahk-scripts-v2](https://github.com/jNizM/ahk-scripts-v2) | Collects standalone v2 scripts and functions | Keep helpers usable through `#Include`, without starting the shortcut application. | MIT |
| [AutoHotkey-LibV2](https://github.com/Nich-Cebolla/AutoHotkey-LibV2) | Collects reusable v2 utilities | Existing libraries should be considered before adding platform wrappers. No additional dependency is needed for the present commands. | MIT |

The comparison covers the inspected READMEs and licence metadata. It is not an audit of those projects or a claim that their workflows are interchangeable.

## Primary references

| Reference | What it establishes | Application |
| --- | --- | --- |
| [AutoHotkey v2 Send documentation](https://www.autohotkey.com/docs/v2/lib/Send.htm) | `SendText` treats most text literally, but translates newlines, tabs and backspaces into keystrokes | Keep arbitrary and multiline output in the preview and copy workflow. |
| [ABN Lookup: format of the ABN](https://abr.business.gov.au/Help/AbnFormat) | The 11-digit ABN checksum subtracts one from the first digit, applies weights and checks divisibility by 89 | Offline checksum reporting using the published worked example `51 824 753 556`. |
| [ASIC Datastream Messages Specification, version 2.80](https://download.asic.gov.au/media/ftefncyp/messspec.pdf) | Appendix B, printed page 144, gives the ACN check-digit algorithm and worked examples | Offline ACN checksum reporting. The former ASIC digit-check web page now redirects to a general ACN page, so the specification supplies the algorithm evidence. |
| [Microsoft: naming files, paths and namespaces](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file) | Reserved filename characters, device names and trailing spaces or full stops | Prepare a filename component as text. No file is renamed. |

ABN and ACN checks establish formatting and checksum properties only. Use [ABN Lookup](https://abr.business.gov.au/) or [ASIC's registers](https://www.asic.gov.au/online-services/search-asics-registers/) for registration information. A checksum cannot establish an entity's identity, active status or GST registration.

## Existing accounting tools

[Accounting Excel Toolkit](https://github.com/ryanduguid/accounting-review-pipeline/tree/main/adapters/accounting-excel-toolkit) already supplies Power Query and VBA helpers. Its `Fx.ABNIsValid.pq` informed the strict identifier input policy: accept digits and spaces, preserve leading zeros and reject other characters. The checksum arithmetic was checked against the primary references above.

[Ozzit](https://github.com/ryanduguid/Ozzit) supplies Excel modelling functions. Financial calculations belong in tools with appropriate numerical checks; the hotkey library handles dates, labels and text preparation.

## Evidence limits

Synthetic Windows tests exercise the library and its native controls. Individual accounting applications, alternate keyboard layouts, remote desktops and firm desktop restrictions need separate checks. The resource comparison does not establish compatibility with them.
