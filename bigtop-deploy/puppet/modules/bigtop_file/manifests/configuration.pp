define bigtop_file::configuration($content = undef, $source = undef, $overrides, $outputFile, $contentType) {
  include bigtop_file::library
  include bigtop_file::tmpfolder
  if ($content != undef and $source != undef) {
    fail('only one of content or source can be defined')
  }
  $configurationFile = $source ? {
    undef   => $name,
    default => $source,
  }
  $configurationOption = $content ? {
    undef   => "--configuration-file ${configurationFile}",
    default => '--configuration "$CONTENT"',
  }
  $yamlOverrides = to_yaml($overrides)
  $tmpSuffix = inline_template('<%= require "securerandom"; SecureRandom.uuid %>')
  $tmpOutputFile = "/tmp/puppet_bigtop_file_merge/${tmpSuffix}"

  $mergeConfigCmd = "merge-config --output-file $tmpOutputFile --content-type $contentType --overrides \"\$OVERRIDES\" $configurationOption"
  $compareCmd = "! cmp ${outputFile} ${tmpOutputFile}"
  $cleanUpCmd = "rm ${tmpOutputFile}"

  exec { "merge:${outputFile}":
    provider    => shell,
    command     => "mv ${tmpOutputFile} ${outputFile}",
    environment => delete(["OVERRIDES=$yamlOverrides", "CONTENT=$content"], "CONTENT="),
    onlyif      => "(${mergeConfigCmd} && ${compareCmd}) || (${cleanUpCmd} && false)",
    path        => '/bin:/usr/bin:/usr/lib/bigtop-utils/bigtop-configure/bin',
    logoutput   => false,
    require     => Package['bigtop-utils'],
  }
}
