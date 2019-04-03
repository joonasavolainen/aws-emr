define bigtop_file::ini($content = undef, $source = undef, $overrides) {
  configuration { $name:
    content => $content,
    source => $source,
    overrides => $overrides,
    outputFile => $name,
    contentType => 'ini',
  }
}