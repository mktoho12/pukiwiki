<?php
// Shows when PHP 4 copies an object, and when it does not.
// "same": the object keeps the reference to itself made in its constructor.
// "COPY": the variable holds a copy, and the reference points to the original.
//
// docker run --rm -v "$PWD/tests/php-compat:/t" pukiwiki-php-compat:php444 php-cgi -q /t/copy-demo.php
// docker run --rm -v "$PWD/tests/php-compat:/t" php:8.5-cli php /t/copy-demo.php

error_reporting(E_ALL);
ini_set('display_errors', '1');

class A
{
	var $self;
	var $v;
	function A() { $this->__construct(); }
	function __construct()
	{
		$this->self = & $this;
		$this->v = 1;
	}
}

function check($label, & $obj)
{
	$obj->v = 9;
	echo $label, ': ', ($obj->self->v == 9 ? 'same' : 'COPY'), "\n";
}

$a = new A();
check('$a = new A()', $a);

function & f1() { $obj = new A(); return $obj; }
$b = & f1();
check('$obj = new A(); return $obj; (function &)', $b);

function & f2() { return new A(); } // Notice on PHP 5 and later
$c = & f2();
check('return new A(); (function &)', $c);

$arr = array(new A());
check('array(new A())', $arr[0]);
