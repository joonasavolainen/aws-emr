Facter.add("kernel_compiler_package") do
    setcode do
    Facter::Util::Resolution.exec("echo gcc`cat /proc/version | grep -oP 'gcc version (.*?) ' | awk -F'[. ]' '{print $3$4;}'`")
    end
end
