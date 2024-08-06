# Some simple scripts for working with xml in nushell

# Recursively drills through single length arrays and content objects until a value is reached
def "xml drill" [] {
  match $in {
    [$inner]              => ($inner | xml drill)
    { content: $content } => ($content | xml drill)
    $other                => $other
  }
}

def "xml get" [tag: string] {
  let target = $in;
  $tag 
    | split row "."
    | reduce -f $target { |item, acc| ($acc | where tag == $item | xml drill) }
}

def "xml with-tag" [name: string value: string] {
  xml drill
    | where ($it.content | where tag == $name | first | xml drill) == $value
    | xml drill
}

def "xml by-id" [id: string] {
  xml with-tag id $id
}

def "xml by-ids" [ids: list<string>] {
  let start = $in;
  $ids | each { |it| $start | xml with-tag id $it }
}

# Simplifies an xml structure, but loses attributes in the process
def "xml simplify" [] {
  let this = $in;
  match $this {
    { content: [$only]} => ($only | xml simplify)
    { content: [..$all] } => ($all | group-by tag | xml simplify groups)
    { content: $content } => $content
    _ => (error make { msg: "Invalid XML" })
  }
}

def "xml simplify groups" [] {
  let this = $in;
  $this | map { |i| 
    match $i {
      [$only] => ($only | xml simplify)
      $other => ($other | each { |j| $j | xml simplify })      
    }
  }
}

def pairs [] {
  let this = $in;
  $this 
    | items {|k,v| { key: $k value: $v } }
}

def map [clr: closure] {
  let this = $in;
  $this
    | pairs
    | reduce --fold {} { |next, acc| $acc | upsert $next.key (do $clr $next.value) }
}

# Returns the item piped in, or the default value if the item is null
def or [default: any] {
  let this = $in;

  if $this == null {
    $default
  } else {
    $this
  }
}
