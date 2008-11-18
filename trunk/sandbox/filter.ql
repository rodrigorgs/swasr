getdb($1)

regex = $3

for rel in relnames {
  $rel = ($rel) [&0 =~ regex || &1 =~ regex]
}

putdb($2)
