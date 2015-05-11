# Public: installs java jre-7u51 and JCE unlimited key size policy files
#
# Examples
#
#    include java
class java (
  $update_version = '45',
  $update_major_version = '7',
  $base_download_url = 'https://s3.amazonaws.com/cylent-boxen/java'
) {
  include boxen::config

  $new_java_version  = "1.${update_major_version}.${update_version}"
  $java_package_name = "${update_major_version}u${update_version}-macosx-x64.dmg"
  $jre_url = "${base_download_url}/jre-${java_package_name}"
  $jdk_url = "${base_download_url}/jdk-${java_package_name}"
  $wrapper = "${boxen::config::bindir}/java"
  $jdk_dir = "/Library/Java/JavaVirtualMachines/jdk1.${update_major_version}.0_${update_version}.jdk"
  $sec_dir = "${jdk_dir}/Contents/Home/jre/lib/security"

  if ((versioncmp($::macosx_productversion_major, '10.10') >= 0) and
    (versioncmp($update_version, '71') < 0) and $update_major_version == '7')
  {
    fail('Yosemite Requires Java 7 with a patch level >= 71 (Bug JDK-8027686)')
  }

  if ((versioncmp($::macosx_productversion_major, '10.10') >= 0) and
    (versioncmp($update_version, '20') < 0) and $update_major_version == '8')
  {
    fail('Yosemite Requires Java 8 with a patch level >= 20 (Bug JDK-8027686)')
  }

  $java_version_installed = regsubst($::java_version, '_', '.')
  $java_version_potential = "1.${update_major_version}.0.${update_version}"
  $java_version_drift     = versioncmp($java_version_installed, $java_version_potential)

  if ($java_version_drift)
  {
    package {
      "jre-${update_major_version}u${update_version}.dmg":
        ensure   => present,
        alias    => 'java-jre',
        provider => pkgdmg,
        source   => $jre_url ;
      "jdk-${update_major_version}u${update_version}.dmg":
        ensure   => present,
        alias    => 'java',
        provider => pkgdmg,
        source   => $jdk_url ;
    }
  }

  file { $wrapper:
    source  => 'puppet:///modules/java/java.sh',
    mode    => '0755'
  }

  # Allow 'large' keys locally.
  # http://www.ngs.ac.uk/tools/jcepolicyfiles
  file { $sec_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'wheel',
    mode    => '0775',
    require => Package['java']
  }

  file { "${sec_dir}/local_policy.jar":
    source  => "puppet:///modules/java/${update_major_version}/local_policy.jar",
    owner   => 'root',
    group   => 'wheel',
    mode    => '0664',
    require => File[$sec_dir]
  }

  file { "${sec_dir}/US_export_policy.jar":
    source  => "puppet:///modules/java/${update_major_version}/US_export_policy.jar",
    owner   => 'root',
    group   => 'wheel',
    mode    => '0664',
    require => File[$sec_dir]
  }
}