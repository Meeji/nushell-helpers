# A few helper functions that convert the output of dotnet commands into structured data.

# List all nuget packages used by the current project
def --wrapped "nget list" [...rest] {
  let rows = (dotnet list package ...$rest | lines | str trim | where $it != "");

  $rows | reduce --fold { proj: "" dotnet: "" table: [] }  { |it, agg| 
    let proj = match ($it | matches "^Project [`'](.+)['`]") {
      [$m] => $m
      _    => $agg.proj
    };

    let dotnet = match ($it | matches '^\[(.+)\]:$') {
      [$m] => $m
      _    => $agg.dotnet
    };

    let table = match ($it | matches '^> (\S+)\s+(\S+)\s+(\S+)\s*?(\S*?)$') {
      [$name, $req, $res, $latest] => ($agg.table ++ {
        name     : $name
        requested: $req
        resolved : $res
        latest   : $latest 
      })
      [$name, $req, $res] => ($agg.table ++ {
        name     : $name
        requested: $req
        resolved : $res
      })
      _ => $agg.table
    };

    { 
      proj  : $proj 
      dotnet: $dotnet
      table : $table
    }
  }
}

def or [value: any] {
  if $in == null { $value } else { $in }
}

def matches [reg: string] {
  parse --regex $reg 
    | values 
    | each {|| first}
    | where $it != null and $it != ""
}

def "on" [
  cls: closure
] {
  match cls($in) { 
    null   => $in 
    $other => $other 
  }
}

def captures [] {
  let values = $in;

  if values == null or values == [] { return null; }
  
  0..10
    | each { |i| [ {value: $'capture($i)' optional: true } ]}
    | each { || into cell-path }
    | each { |p| $values | get $p }
}
