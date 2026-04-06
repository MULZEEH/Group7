import bz2
import os
import re
import subprocess
import threading
import tkinter as tk
from tkinter import filedialog, messagebox
import zipfile

try:
    from tkinterdnd2 import DND_FILES, TkinterDnD
except Exception:
    DND_FILES = None
    TkinterDnD = None


class StartApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Launcher")
        self.root.geometry("560x360")
        self.root.resizable(False, False)
        self.root.configure(bg="#1e1e1e")

        self.selected_file_path = ""
        self.elapsed_seconds = 0
        self.timer_running = False
        self.process = None

        self._build_ui()

    def _build_ui(self) -> None:
        self.timer_label = tk.Label(
            self.root,
            text="00:00",
            font=("Consolas", 44, "bold"),
            fg="#9be564",
            bg="#1e1e1e",
        )
        self.timer_label.pack(pady=(20, 22))

        center_frame = tk.Frame(self.root, bg="#1e1e1e")
        center_frame.pack(expand=True)

        # "Minecraft style" approximation with chunky colors and bold text.
        self.start_btn = tk.Button(
            center_frame,
            text="START",
            font=("Arial Black", 28, "bold"),
            width=10,
            height=2,
            bg="#6ab04c",
            fg="#101010",
            activebackground="#7ed957",
            activeforeground="#101010",
            relief="raised",
            bd=6,
            state=tk.DISABLED,
            command=self.start_program,
        )
        self.start_btn.pack()

        bottom_frame = tk.Frame(self.root, bg="#1e1e1e")
        bottom_frame.pack(fill="x", pady=(8, 18))

        drop_frame = tk.Frame(bottom_frame, bg="#2a2a2a", bd=2, relief="groove")
        drop_frame.pack(anchor="center", padx=16, ipadx=8, ipady=6)

        self.add_btn = tk.Button(
            drop_frame,
            text="+",
            font=("Arial", 18, "bold"),
            width=3,
            bg="#3a3a3a",
            fg="#f0f0f0",
            activebackground="#4d4d4d",
            activeforeground="#ffffff",
            relief="raised",
            bd=2,
            command=self.select_file,
        )
        self.add_btn.grid(row=0, column=0, padx=(8, 10), pady=6)

        self.file_label = tk.Label(
            drop_frame,
            text="Drop .zip/.bz here or press +",
            font=("Arial", 10),
            fg="#cfcfcf",
            bg="#2a2a2a",
            anchor="center",
            justify="center",
            width=45,
        )
        self.file_label.grid(row=0, column=1, padx=(0, 8), pady=6)

        self.drop_hint = tk.Label(
            drop_frame,
            text="Drag & Drop enabled" if DND_FILES else "Install tkinterdnd2 for drag & drop",
            font=("Arial", 9),
            fg="#a6a6a6",
            bg="#2a2a2a",
        )
        self.drop_hint.grid(row=1, column=0, columnspan=2, pady=(0, 4))

        if DND_FILES and hasattr(self.root, "drop_target_register"):
            drop_frame.drop_target_register(DND_FILES)
            drop_frame.dnd_bind("<<Drop>>", self.on_drop_file)
            self.file_label.drop_target_register(DND_FILES)
            self.file_label.dnd_bind("<<Drop>>", self.on_drop_file)

    def select_file(self) -> None:
        file_path = filedialog.askopenfilename(
            title="Select ZIP or BZ file",
            filetypes=[("ZIP/BZ files", "*.zip *.bz"), ("All files", "*.*")],
        )
        if not file_path:
            return
        self._load_selected_file(file_path)

    def on_drop_file(self, event) -> None:
        dropped = event.data.strip()
        # Handle wrapped paths from DnD, including spaces: "{/path with space/file.zip}"
        paths = re.findall(r"\{([^}]+)\}|(\S+)", dropped)
        flat_paths = [a or b for a, b in paths if (a or b)]
        if not flat_paths:
            return
        self._load_selected_file(flat_paths[0])

    def _is_valid_file(self, file_path: str) -> bool:
        lowered = file_path.lower()
        if lowered.endswith(".zip"):
            return zipfile.is_zipfile(file_path)
        if lowered.endswith(".bz"):
            try:
                with bz2.open(file_path, "rb") as bz_file:
                    bz_file.read(1)
                return True
            except Exception:
                return False
        return False

    def _load_selected_file(self, file_path: str) -> None:
        if not self._is_valid_file(file_path):
            self.selected_file_path = ""
            self.file_label.config(text="Invalid file. Select a real .zip or .bz file.")
            self.start_btn.config(state=tk.DISABLED)
            messagebox.showerror("Invalid file", "You must select a valid .zip or .bz file.")
            return

        self.selected_file_path = file_path
        self.file_label.config(text=f"Loaded: {self.selected_file_path}")
        self.start_btn.config(state=tk.NORMAL)

    def start_program(self) -> None:
        if self.timer_running:
            self.timer_running = False
            self._set_start_state()
            return

        if not self.selected_file_path:
            messagebox.showerror("Missing file", "Please load a .zip or .bz file before starting.")
            self.start_btn.config(state=tk.DISABLED)
            return

        script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "start.sh")
        if not os.path.exists(script_path):
            messagebox.showerror("Missing script", f"'start.sh' not found at:\n{script_path}")
            return

        self.timer_running = True
        self.elapsed_seconds = 0
        self._set_stop_state()
        self._tick_timer()

        try:
            self.process = subprocess.Popen(["bash", script_path, self.selected_file_path])
            watcher = threading.Thread(target=self._wait_for_script_end, daemon=True)
            watcher.start()
        except Exception as exc:
            self.timer_running = False
            self._set_start_state()
            messagebox.showerror("Launch error", f"Could not run start.sh:\n{exc}")

    def _set_stop_state(self) -> None:
        self.start_btn.config(
            text="STOP",
            bg="#d35454",
            activebackground="#e06767",
            fg="#101010",
            activeforeground="#101010",
        )

    def _set_start_state(self) -> None:
        self.start_btn.config(
            text="START",
            bg="#6ab04c",
            activebackground="#7ed957",
            fg="#101010",
            activeforeground="#101010",
        )

    def _wait_for_script_end(self) -> None:
        if self.process is None:
            return
        return_code = self.process.wait()
        self.process = None
        self.root.after(0, lambda: self._on_script_finished(return_code))

    def _on_script_finished(self, return_code: int) -> None:
        self.timer_running = False
        self._set_start_state()
        if return_code == 0:
            messagebox.showinfo("Finished", "start.sh finished successfully.")
        else:
            messagebox.showerror("Finished with errors", f"start.sh exited with code {return_code}.")

    def _tick_timer(self) -> None:
        if not self.timer_running:
            return

        minutes = self.elapsed_seconds // 60
        seconds = self.elapsed_seconds % 60
        self.timer_label.config(text=f"{minutes:02d}:{seconds:02d}")
        self.elapsed_seconds += 1
        self.root.after(1000, self._tick_timer)


def main() -> None:
    root = TkinterDnD.Tk() if TkinterDnD else tk.Tk()
    app = StartApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
