﻿using Serilog;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;

namespace hirs {
    public interface IHardwareManifest {
        public static readonly string pluginsPath =
            Path.Combine(Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName), "plugins");
        string Name {
            get;
        }
        string Description {
            get;
        }

        int Execute(string[] args);
        string asJsonString();
    }
}
