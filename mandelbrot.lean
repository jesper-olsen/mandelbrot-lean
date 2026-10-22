/-!
# Mandelbrot

Generates Mandelbrot set visualizations in ASCII or for gnuplot.
Lean port of mandelbrot.c for the cross-language comparison project.
Arguments are given as key=value, exactly as in the C version.

Build:
  lake build                          (emits .lake/build/bin/mandelbrot)

Usage:
  .lake/build/bin/mandelbrot
  .lake/build/bin/mandelbrot width=120 ll_x=-0.75 ll_y=0.1 ur_x=-0.74 ur_y=0.11
  .lake/build/bin/mandelbrot png=1 width=800 height=600 > mandelbrot.dat
-/

structure Config where
  width   : Nat   := 100
  height  : Nat   := 75
  png     : Bool  := false
  llX     : Float := -1.2
  llY     : Float := 0.2
  urX     : Float := -1.0
  urY     : Float := 0.35
  maxIter : Nat   := 255

def symbols : ByteArray := "MW2a_. ".toUTF8

/-! Float constants are top-level definitions, which Lean initialises once. A float
literal written inside the hot loop can compile to a slow `Float.ofScientific` call on
every iteration. Likewise `UInt64.toFloat` is used instead of `Nat.toFloat`, which is
slow. -/

@[noinline] def two : Float := 2.0
@[noinline] def four : Float := 4.0

/-- Maps an iteration count in [0, maxIter] to an ASCII character (as a byte).
    `maxIterF` is maxIter as a Float, `scaleF` is symbols.size - 1 as a Float. -/
def cnt2char (value : USize) (maxIterF scaleF : Float) : UInt8 :=
  let idx := (value.toUInt64.toFloat / maxIterF * scaleF).toUInt64.toNat
  if h : idx < symbols.size then symbols[idx] else 32

/-- Escape time for the point c = cr + ci*i; returns maxIter - iterations used.
    Terminates because iter climbs to maxIter, but that is not proved, hence `partial`. -/
partial def escapeTime (cr ci : Float) (maxIter : USize) : USize :=
  go 0 0.0 0.0
where
  go (iter : USize) (zr zi : Float) : USize :=
    if iter < maxIter then
      let zr2 := zr * zr
      let zi2 := zi * zi
      if zr2 + zi2 > four then
        maxIter - iter
      else
        go (iter + 1) (zr2 - zi2 + cr) (two * zr * zi + ci)
    else
      maxIter - iter

/-- Appends the decimal digits of n. -/
partial def pushDecimal (buf : ByteArray) (n : USize) : ByteArray :=
  if n < 10 then
    buf.push (48 + n.toUInt8)
  else
    (pushDecimal buf (n / 10)).push (48 + (n % 10).toUInt8)

/-- Writes buf to out once it has grown large enough; returns the (possibly emptied) buffer. -/
def flushIfFull (out : IO.FS.Stream) (buf : ByteArray) : IO ByteArray := do
  if buf.size >= 65536 then
    out.write buf
    pure ByteArray.empty
  else
    pure buf

/-- Renders the Mandelbrot set as ASCII art to stdout. -/
def asciiOutput (cfg : Config) : IO Unit := do
  let out ← IO.getStdout
  let fwidth := cfg.urX - cfg.llX
  let fheight := cfg.urY - cfg.llY
  let widthF := cfg.width.toUInt64.toFloat
  let heightF := cfg.height.toUInt64.toFloat
  let maxIter := cfg.maxIter.toUSize
  let maxIterF := cfg.maxIter.toUInt64.toFloat
  let scaleF := (symbols.size - 1).toUInt64.toFloat
  let mut buf := ByteArray.empty
  for y in [0:cfg.height] do
    let imag := cfg.urY - y.toUInt64.toFloat * fheight / heightF
    for x in [0:cfg.width] do
      let real := cfg.llX + x.toUInt64.toFloat * fwidth / widthF
      buf := buf.push (cnt2char (escapeTime real imag maxIter) maxIterF scaleF)
    buf := buf.push 10
    buf ← flushIfFull out buf
  out.write buf
  out.flush

/-- Generates comma-separated iteration counts for gnuplot (bottom row first). -/
def gptextOutput (cfg : Config) : IO Unit := do
  let out ← IO.getStdout
  let fwidth := cfg.urX - cfg.llX
  let fheight := cfg.urY - cfg.llY
  let widthF := cfg.width.toUInt64.toFloat
  let heightF := cfg.height.toUInt64.toFloat
  let maxIter := cfg.maxIter.toUSize
  let mut buf := ByteArray.empty
  for i in [0:cfg.height] do
    let y := cfg.height - 1 - i
    let imag := cfg.urY - y.toUInt64.toFloat * fheight / heightF
    for x in [0:cfg.width] do
      let real := cfg.llX + x.toUInt64.toFloat * fwidth / widthF
      if x > 0 then buf := (buf.push 44).push 32  -- ", "
      buf := pushDecimal buf (escapeTime real imag maxIter)
    buf := buf.push 10
    buf ← flushIfFull out buf
  out.write buf
  out.flush

/-- Parses a decimal floating point literal: [+-]digits[.digits][(e|E)[+-]digits]. -/
def parseFloat? (s : String) : Option Float := do
  let (neg, cs) := match s.toList with
    | '-' :: r => (true, r)
    | '+' :: r => (false, r)
    | r => (false, r)
  let (intDigits, rest) := cs.span Char.isDigit
  let (fracDigits, rest) := match rest with
    | '.' :: r => r.span Char.isDigit
    | r => ([], r)
  if intDigits.isEmpty && fracDigits.isEmpty then none
  let (expNeg, expDigits) ← match rest with
    | [] => some (false, [])
    | e :: r =>
      if e == 'e' || e == 'E' then
        let (expNeg, r) := match r with
          | '-' :: r => (true, r)
          | '+' :: r => (false, r)
          | r => (false, r)
        if r.isEmpty || !r.all Char.isDigit then none else some (expNeg, r)
      else none
  let toNat (ds : List Char) : Nat := ds.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0
  let mantissa := toNat (intDigits ++ fracDigits)
  let exp : Int := (if expNeg then -(toNat expDigits : Int) else (toNat expDigits : Int))
                   - fracDigits.length
  let f := if exp >= 0 then Float.ofScientific mantissa false exp.toNat
           else Float.ofScientific mantissa true (-exp).toNat
  some (if neg then -f else f)

def warnInvalid (key value : String) : IO Unit :=
  IO.eprintln s!"Warning: Invalid value '{value}' for '{key}'"

/-- Applies an integer-valued argument; warns and keeps cfg if unparseable. -/
def setInt (key value : String) (cfg : Config) (f : Config → Int → Config) : IO Config :=
  -- String.toInt? rejects a leading '+', which C's atoi accepts.
  match (if value.startsWith "+" then value.drop 1 else value).toInt? with
  | some n => pure (f cfg n)
  | none => do warnInvalid key value; pure cfg

/-- Applies a float-valued argument; warns and keeps cfg if unparseable. -/
def setFloat (key value : String) (cfg : Config) (f : Config → Float → Config) : IO Config :=
  match parseFloat? value with
  | some x => pure (f cfg x)
  | none => do warnInvalid key value; pure cfg

/-- Parses a single "key=value" command-line argument into cfg. -/
def parseArg (cfg : Config) (arg : String) : IO Config := do
  match arg.splitOn "=" with
  | [] | [_] =>
    IO.eprintln s!"Warning: Ignoring invalid argument '{arg}'"
    pure cfg
  | key :: rest =>
    let value := "=".intercalate rest
    match key with
    | "width"    => setInt key value cfg fun c n => { c with width := n.toNat }
    | "height"   => setInt key value cfg fun c n => { c with height := n.toNat }
    | "png"      => setInt key value cfg fun c n => { c with png := n != 0 }
    | "ll_x"     => setFloat key value cfg fun c x => { c with llX := x }
    | "ll_y"     => setFloat key value cfg fun c x => { c with llY := x }
    | "ur_x"     => setFloat key value cfg fun c x => { c with urX := x }
    | "ur_y"     => setFloat key value cfg fun c x => { c with urY := x }
    | "max_iter" => setInt key value cfg fun c n => { c with maxIter := n.toNat }
    | _ =>
      IO.eprintln s!"Warning: Unknown parameter '{key}'"
      pure cfg

def main (args : List String) : IO UInt32 := do
  let mut cfg : Config := {}
  for a in args do
    cfg ← parseArg cfg a
  try
    if cfg.png then gptextOutput cfg else asciiOutput cfg
  catch
    | .resourceVanished .. => pure ()  -- the reader closed the pipe (e.g. `| head`)
    | e => throw e
  return 0
