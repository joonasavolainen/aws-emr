define bigtop_file::properties($content = undef, $source = undef, $overrides) {
  configuration { $name:
    content => $content,
    source => $source,
    overrides => $overrides,
    outputFile => $name,
    contentType => 'properties',
  }
}