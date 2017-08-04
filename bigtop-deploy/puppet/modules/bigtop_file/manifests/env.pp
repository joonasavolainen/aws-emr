define bigtop_file::env($content = undef, $source = undef, $overrides) {
  configuration { $name:
    content => $content,
    source => $source,
    overrides => $overrides,
    outputFile => $name,
    contentType => 'env',
  }
}