import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;

enum CalcState {
  csFirst, csValid, csError
};

class Calculator {
  protected bool bStarted = false;
  protected CalcState calcState = CalcState.csFirst;
  protected string sNumber = "0";
  protected char charSign = ' ';

  protected string cOperator = "=";
  protected string cLastOperator = " ";
  protected double dLastResult = 0;
  protected double dOperand = 0;
  protected double dMemory = 0;
  protected bool bHaveMemory = false;
  protected double dDisplayNumber = 0;
  protected bool bHexShown = false;
  protected bool bLog = false;

  public int iMaxDecimals = 10;
  public int iMaxDigits = 30;

  this() {
  //  reset();
  }

  ~this() {
    //  reset();
  }

  override string toString() {
    return charSign ~ sNumber;
  }

  public string getNumber() {
    return sNumber;
  }

  public string repeat_char(char c, int n) {
  /*  string str = "";
    str repa
    char[] chars = new char[n];
    //Arrays.fill(chars, c);
    return chars;*/
    return rightJustify("", n, c);
  }

  public string format_it(double d) {
    //DecimalFormat df = new DecimalFormat("#0.#");
    //return df.format(d);
    //return format("#0.#", d);
    return format("%g", d);    
  }

  public double getDisplay() {
    return dDisplayNumber;
  }

  public void setDisplay(double value, bool bKeepZeroes) {

    dDisplayNumber = value;
    int iZeroes = 0;
    int p = sNumber.indexOf('.');

    if (bKeepZeroes && p >= 0) {
      int i = sNumber.length - 1;
      while (i > p) {
        if (sNumber[i] == '0')
          iZeroes++;
        else
          break;
      }
    }

    string s = format_it(value);

    if (iZeroes > 0) {
      s = s ~ repeat_char('0', iZeroes);
    }

    // Move the sign to a variable
    if (s[0] == '-') {
      s = s[1..$];
      charSign = '-';
    } else
      charSign = ' ';

    if (s.length > iMaxDigits + 1 + iMaxDecimals)
      error();
    else {
      if (s.endsWith("."))
        s = s[0..s.length - 1];
      sNumber = s;
    }
  }

  protected bool check(bool initZero) {
    if (calcState == CalcState.csFirst) {
      calcState = CalcState.csValid;
      dDisplayNumber = 0;
      if (initZero)
        sNumber = "0";
      else
        sNumber = "";
      return true;
    }
    return false;
  }

  void process(char c) {
    string s = "" ~ c;
    process(s);
  }

  public void process(string key) {

    string s;

    key = key.toUpper();

    if ((calcState == CalcState.csError) && (key != "CR"))
      key = " ";
    double r = 0;
    if (bHexShown) {
      r = getDisplay();
      setDisplay(r, false);
      bHexShown = false;
      if (key=="H")
        key = " ";
    }

    if (key=="X^Y")
      key = "^";
    else if (key=="_")
      key = "+/-";

    r = getDisplay();
    if (key=="ON")
      reset();
    else if (key=="AC")
      clear();
    else if (key=="CR") {
      if (!check(true))
        setDisplay(0, true);
      calcState = CalcState.csFirst;
    } else if (key=="1/X") {
      if (r == 0)
        error();
      else
        setDisplay(1 / r, false);
    } else if (key=="SQRT") {
      if (r < 0)
        error();
      else
        setDisplay(sqrt(r), false);
    } else if (key=="LOG") {
      if (r <= 0)
        error();
      else
        setDisplay(log(r), false);
    } else if (key=="X^2")
      setDisplay(r * r, false);
    else if (key=="+/-") {
      if (charSign == ' ')
        charSign = '-';
      else
        charSign = ' ';
      r = getDisplay();
      setDisplay(-r, true);
    } else if (key=="M+") {
      dMemory = dMemory + r;
      bHaveMemory = true;
    } else if (key=="M-") {
      dMemory = dMemory - r;
      bHaveMemory = true;
    } else if (key=="MR") {
      check(false);
      setDisplay(dMemory, false);
    } else if (key=="MC") {
      dMemory = 0;
      bHaveMemory = false;
    } else if (key=="DEL") // Delete
    {
      check(true);
      if (sNumber.length == 1)
        sNumber = "0";
      else
        sNumber = sNumber[0..sNumber.length - 2];
      setDisplay(to!double(sNumber), true);// { !!! }

    }

    else if (key=="00") {
      if (sNumber.length < iMaxDigits - 1) {
        check(true);
        if (sNumber!="0") {
          sNumber = sNumber ~ key;
          dDisplayNumber = to!double(sNumber);
        }
      }
    }
    else if (key=="0") {
      if (sNumber.length < iMaxDigits) {
        check(true);
        if (sNumber!="0") {
          sNumber = sNumber ~ key;
          dDisplayNumber = to!double(sNumber);
        }
      }
    }
    else if (key >="1" && key <="9") {
      if (sNumber.length < iMaxDigits) {
        check(false);
        if (sNumber=="0")
          sNumber = "";
        sNumber = sNumber ~ key;
        dDisplayNumber = to!double(sNumber);
      }
    } else if (key==".") {
      check(true);
      if (sNumber.indexOf('.') < 0)
        sNumber = sNumber ~ '.';
    } else if (key=="H") {
      r = getDisplay();
      sNumber = format("hhhhhhhh", round(r));
      bHexShown = true;
    } else { // finally else '^', '+', '-', '*', '/', '%', '='
      if (key=="=" && (calcState == CalcState.csFirst)) {
        // for repeat last operator
        calcState = CalcState.csValid;
        r = dLastResult;
        cOperator = cLastOperator;
      } else
        r = getDisplay();

      if (calcState == CalcState.csValid) {
        bStarted = true;
        if (cOperator=="=")
          s = " ";
        else
          s = getOperator();

        if (bLog)
          write_log(s ~ format_it(r));

        calcState = CalcState.csFirst;
        cLastOperator = cOperator;
        dLastResult = r;
        if (key=="%") {
          if (cOperator=="+"
            || cOperator=="-")
            r = dOperand * r / 100;
          else if (cOperator=="*"
               || cOperator=="/")
            r = r / 100;
        }

        else if (cOperator=="^") {
          if ((dOperand == 0) && (r <= 0))
            error();
          else
            setDisplay(pow(dOperand, r), false);
        } else if (cOperator=="+")
          setDisplay(dOperand + r, false);
        else if (cOperator=="-")
          setDisplay(dOperand - r, false);
        else if (cOperator=="*")
          setDisplay(dOperand * r, false);
        else if (cOperator=="/") {
          if (r == 0)
            error();
          else
            setDisplay(dOperand / r, false);
        }
      }
      if (bLog && key=="=")
        write_log('=' ~ sNumber);

      cOperator = key;
      dOperand = getDisplay();

    }

    refresh();
  }

  void scanline(char[] buf) {
    int i = 0;

    while(i < buf.length - 1) {
      process(buf[i]);
      i++;
    }    
  }

  public void clear() {
    if (bLog && bStarted)
      write_log(repeat_char('-', 10));//just a separator
    bStarted = false;
    calcState = CalcState.csFirst;
    sNumber = "0";
    charSign = ' ';
    cOperator = "=";
    refresh();
  }

  public void reset() {
    clear();
    bHaveMemory = false;
    dMemory = 0;
  }

  protected void error() {
    calcState = CalcState.csError;
    sNumber = "Error";
    charSign = ' ';
    refresh();
  }

  // This methods need to override;
  public void write_log(string S) { // virtual

  }

  public void refresh() { // virtual

  }

  public string getOperator() {
    if (cOperator=="*")
      return "×";
    else if (cOperator=="/")
      return "÷";
    else
      return cOperator;
  }
}

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