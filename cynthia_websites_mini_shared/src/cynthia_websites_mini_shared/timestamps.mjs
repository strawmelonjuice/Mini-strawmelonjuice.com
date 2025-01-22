export function parse(datestr)
{
	const yy = datestr.substring(0, 4);
	const mo = datestr.substring(5, 7);
	const dd = datestr.substring(8, 10);
	const hh = datestr.substring(11, 13);
	const mi = datestr.substring(14, 16);
	const ss = datestr.substring(17, 19);
	const tzs = datestr.substring(19, 20);
	const tzhh = datestr.substring(20, 22);
	const tzmi = datestr.substring(23, 25);
	const myutc = Date.UTC(yy - 0, mo - 1, dd - 0, hh - 0, mi - 0, ss - 0);
	const tzos = (tzs + (tzhh * 60 + tzmi * 1)) * 60000;
	return new Date(myutc - tzos);
}
