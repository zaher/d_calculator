import std.stdio;
import std.string;
import std.math;
import std.array, std.range;

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

	public int iMaxDecimals = 10;
	public int iMaxDigits = 30;

	public void Calculator() {
	//	reset();
	}

	override string toString() {
		return charSign ~ sNumber;
	}

	public string getNumber() {
		return sNumber;
	}

/*	public string getSign() {
		return string.valueOf(charSign);
	}
*/
/*	public string repeat(char c, int n) {
		string str = "";
		str repa
		char[] chars = new char[n];
		//Arrays.fill(chars, c);
		return chars;
	}
*/
	public string format_it(double d) {
		//DecimalFormat df = new DecimalFormat("#0.#");
		//return df.format(d);
		return format("#0.#", d);
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
			s = s ~ rightJustify("", iZeroes, '0'); 
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
				setDisplay(log2(r), false);
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
			setDisplay(sNumber.toDouble, true);// { !!! }
		}

		else if (key.equals("00")) {
			if (sNumber.length() < iMaxDigits - 1) {
				check(true);
				if (!sNumber.equals("0")) {
					sNumber = sNumber + key;
					dDisplayNumber = Double.parseDouble(sNumber);
				}
			}
		}
		else if (key.equals("0")) {
			if (sNumber.length() < iMaxDigits) {
				check(true);
				if (!sNumber.equals("0")) {
					sNumber = sNumber + key;
					dDisplayNumber = Double.parseDouble(sNumber);
				}
			}
		}
		else if (key.compareTo("1") >= 0 && (key.compareTo("9") <= 0)) {
			if (sNumber.length() < iMaxDigits) {
				check(false);
				if (sNumber.equals("0"))
					sNumber = ""; 
				sNumber = sNumber + key;
				dDisplayNumber = Double.parseDouble(sNumber);
			}
		} else if (key.equals(".")) {
			check(true);
			if (sNumber.indexOf('.') < 0)
				sNumber = sNumber + '.';
		} else if (key.equals("H")) {
			r = getDisplay();
			sNumber = Long.toHexString(Math.round(r));
			bHexShown = true;
		} else { // finally else '^', '+', '-', '*', '/', '%', '='
			if (key.equals("=") && (calcState == CalcState.csFirst)) {
				// for repeat last operator
				calcState = CalcState.csValid;
				r = dLastResult;
				cOperator = cLastOperator;
			} else
				r = getDisplay();

			if (calcState == CalcState.csValid) {
				bStarted = true;
				if (cOperator.equals("="))
					s = " ";
				else
					s = getOperator();

				log(s + format(r));

				calcState = CalcState.csFirst;
				cLastOperator = cOperator;
				dLastResult = r;
				if (key.equals("%")) {
					if (cOperator.equals("+")
						|| cOperator.equals("-"))
						r = dOperand * r / 100;
					else if (cOperator.equals("*")
							 || cOperator.equals("/"))
						r = r / 100;
				}

				else if (cOperator.equals("^")) {
					if ((dOperand == 0) && (r <= 0))
						error();
					else
						setDisplay(Math.pow(dOperand, r), false);
				} else if (cOperator.equals("+"))
					setDisplay(dOperand + r, false);
				else if (cOperator.equals("-"))
					setDisplay(dOperand - r, false);
				else if (cOperator.equals("*"))
					setDisplay(dOperand * r, false);
				else if (cOperator.equals("/")) {
					if (r == 0)
						error();
					else
						setDisplay(dOperand / r, false);
				}
			}
			if (key.equals("="))
				log('=' + sNumber);

			cOperator = key;
			dOperand = getDisplay();

		}

		refresh();
	}

	public void clear() {
		if (bStarted)
			log(repeat('-', 10));//just a separator
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
	public void log(string S) { // virtual

	}

	public void refresh() { // virtual

	}

	public string getOperator() {
		if (cOperator.equals("*")) 
			return "×";
		else if (cOperator.equals("/")) 
			return "÷";
		else
			return cOperator;					

	}
}


int main(string[] argv)
{
    writeln("Calc");
    return 0;
}
