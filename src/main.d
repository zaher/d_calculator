import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import calculator;

int main(string[] argv)
{
  Calculator calculator = new Calculator;

  char[] buf;

  writeln("=== ", calculator.getDisplay, " ===");
  while (readln(buf)) {
    if (buf.strip.empty)
      break;
    if (buf[buf.length - 1] != '=')
      buf = buf ~ '=';
    calculator.scanline(buf);
    writeln("=== ", calculator.getDisplay, " ===");
  }
  return 0;
}