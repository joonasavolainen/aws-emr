Facter.add("kernel_devel_releasever") do
    setcode do
        releasever=Facter::Util::Resolution.exec("yum version nogroups | grep Installed | awk -F'[ /]' '{print $2;}'")

        Facter::Util::Resolution.exec("yum list kernel-devel-" << Facter.value(:kernelrelease) << " --releasever=" << releasever)

        if $?.exitstatus == 0
            releasever
        else
            Facter.value(:operatingsystemrelease)
        end
    end
end
