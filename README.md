# Entropy Setup Manager
> Simple CLI manager script for setup scripts in Entropy Linux

![image](https://github.com/user-attachments/assets/ad4f6889-91a3-4376-9029-4fcebe18dd2a)


---

## Setup
> Run `setup.sh` for quick install, or execute:
```bash
sudo sh -c 'curl -fsSL https://raw.githubusercontent.com/Entropy-Linux/Entropy-Setup-Manager/refs/heads/main/setup.sh -o /tmp/setup.sh && chmod +x /tmp/setup.sh && /tmp/setup.sh'
```

---


### How to:
> Important information:
- Dependencies: `git jq dialog tree`
- Manager looks for `.json` files within `.data/` directory.
- Specify `.json` file in runtime with a `--data <path/file.json>` flag.
- Scripts execute in same order as defined in `data.json` (top to bottom)
- Spaces in `data.json` are prohibited! (will display null null)
- After installation with `setup.sh`, project's root dir is `/bin/setup-manager/`

### Example `data.json`
> Path defaults to `/bin/setup-manager/scripts/`
```json
{
  "First_Script": "script.sh",
  "Another_Module": "another.sh"
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
├── scripts
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
