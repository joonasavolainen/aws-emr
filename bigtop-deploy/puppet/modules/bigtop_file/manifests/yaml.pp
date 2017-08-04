define bigtop_file::yaml($content = undef, $source = undef, $overrides) {
  configuration { $name:
    content => $content,
    source => $source,
    overrides => $overrides,
    outputFile => $name,
    contentType => 'yaml',
  }
}