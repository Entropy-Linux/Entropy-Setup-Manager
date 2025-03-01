# Entropy Setup Manager
> Simple CLI manager script for setup scripts in Entropy Linux

---

### Dependencies:
`git jq dialog`

### How to:
> Important information:
- Manager looks for `.json` files within `.data/` directory.
- Specify `.json` file in runtime with a `--data <path/file.json>` flag.
- Scripts execute in same order as defined in `data.json` (top to bottom)
- Spaces in `data.json` are prohibited! (will display null null)
### Example `data.json`
```json
{
  "First_Script": "modules/script.sh",
  "Another_Module": "modules/another.sh"
}
```

### Project structure:
```
.Entropy-Setup-Manager
├── setup.sh
├── esm.sh
├── data
│   ├── ...
│   │   ├── ...
├── modules
│   ├── ...
├── README.md
└── LICENSE
```

### `.data/` Directory structure:
```
.data
├── Generic.json
├── Arch
│   ├── Generic.json
│   └── Desktop.json
└── Debian
│   ├── Generic.json
│   └── Server.json
```

---
