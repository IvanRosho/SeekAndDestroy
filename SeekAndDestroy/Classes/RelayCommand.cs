using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace SeekAndDestroy.Classes {
    public class AsyncRelayCommand : ICommand {
        public virtual event EventHandler CanExecuteChanged;

        private readonly Func<Task> handler;
        private readonly Func<object, Task> handlerParameter;
        private bool enabled;
        private Task task;

        public AsyncRelayCommand(Func<Task> handler, bool enabled = true) {
            this.handler = handler;
            this.Enabled = enabled;
        }

        public AsyncRelayCommand(Func<object, Task> handler, bool enabled = true) {
            this.handlerParameter = handler;
            this.Enabled = enabled;
        }

        public virtual bool CanExecute(object parameter) => this.Enabled && (this.task == null || this.task.IsCompleted);

        public virtual async void Execute(object parameter) {
            if (this.handler != null)
                this.task = handler();
            else if (this.handlerParameter != null)
                this.task = handlerParameter(parameter);
            else
                return;

            try {
                this.CanExecuteChanged?.Invoke(this, EventArgs.Empty);
                await this.task;
            }
            finally {
                this.CanExecuteChanged?.Invoke(this, EventArgs.Empty);
            }
        }

        public virtual bool Enabled {
            get => this.enabled;
            set {
                if (value == this.enabled)
                    return;

                this.enabled = value;
                this.CanExecuteChanged?.Invoke(this, EventArgs.Empty);
            }
        }
    }
}
