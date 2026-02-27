using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.Classes {
    public class BaseViewModel {
        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged<T>(T oldvalue, T newvalue, Action onDifference, string propName) {
            if (!Equals(oldvalue, newvalue)) {
                onDifference?.Invoke();
                OnPropertyChanged(propName);
            }
        }

        protected virtual void OnPropertyChanged(string propName) {
            RaisePropertyChanged(propName);
        }

        protected virtual void RaisePropertyChanged([CallerMemberName] string propName = "") {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propName));
        }
    }
}
