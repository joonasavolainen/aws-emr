define bigtop_file::conf($content = undef, $source = undef, $overrides) {
  configuration { $name:
    content => $content,
    source => $source,
    overrides => $overrides,
    outputFile => $name,
    contentType => 'conf',
  }
}