import csv
import re
from urllib.parse import urlparse, parse_qs, unquote

html_content = """
<table class="list " border="0" cellspacing="0" cellpadding="0" id="list_table">
                    <tbody id="list_body"><tr class="color1 " style="" id="row_0">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox0" id="" type="checkbox" value="_dmarc.chilquintas.cl.">
<input name="checkbox0_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=_dmarc.chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=TXT&amp;rr_data=%22v%3DDMARC1%5C%3Bp%3Dquarantine%5C%3Bpct%3D100%5C%3Brua%3Dmailto%3Apostmaster%40chilquintas.cl%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
_dmarc.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"v=DMARC1\;p=quarant...
</td>
</tr>
<tr class="color2 " style="" id="row_1">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox1" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox1_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=TXT&amp;rr_data=%22google-site-verification%3DMp9-Dbfdhsfo7o-8CjeFpi42CgMclY_at-_sMQoHGiA%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"google-site-verific...
</td>
</tr>
<tr class="color1 " style="" id="row_2">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox2" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox2_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=TXT&amp;rr_data=%2204042023%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"04042023"
</td>
</tr>
<tr class="color2 " style="" id="row_3">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox3" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox3_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=TXT&amp;rr_data=%22v%3Dspf1+include%3Aspf.protection.outlook.com+ip4%3A200.72.40.112%2F32+ip4%3A200.72.40.123%2F32+a+mx+-all%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"v=spf1 include:spf....
</td>
</tr>
<tr class="color1 " style="" id="row_4">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox4" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox4_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=TXT&amp;rr_data=%22MS%3Dms72132672%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"MS=ms72132672"
</td>
</tr>
<tr class="color2 " style="" id="row_5">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox5" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox5_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=TXT&amp;rr_data=%22google-site-verification%3D3ADrIVuhb3xPZj0dOS--tFybaMA_iEAOPCF7t6Ck6b8%22" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
TXT
</td>
<td class="last" align="left" style="">
"google-site-verific...
</td>
</tr>
<tr class="color1 " style="" id="row_6">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox6" disabled="" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox6_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=SOA&amp;rr_data=ns1.chilquinta.cl.+hostmaster.ns1.chilquinta.cl.+2026030402+10800+3600+604800+86400" id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
SOA
</td>
<td class="last" align="left" style="">
ns1.chilquinta.cl. h...
</td>
</tr>
<tr class="color2 " style="" id="row_7">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox7" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox7_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=NS&amp;rr_data=ns2.chilquinta.cl." id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
NS
</td>
<td class="last" align="left" style="">
ns2.chilquinta.cl.
</td>
</tr>
<tr class="color1 " style="" id="row_8">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox8" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox8_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=NS&amp;rr_data=ns1.chilquinta.cl." id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
NS
</td>
<td class="last" align="left" style="">
ns1.chilquinta.cl.
</td>
</tr>
<tr class="color2 " style="" id="row_9">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox9" id="" type="checkbox" value="chilquintas.cl.">
<input name="checkbox9_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=MX&amp;rr_data=0+chilquintas-cl.mail.protection.outlook.com." id="" onmouseup="" title="" class="" onmousedown="" target="">
chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
MX
</td>
<td class="last" align="left" style="">
0 chilquintas-cl.mai...
</td>
</tr>
<tr class="color1 " style="" id="row_10">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox10" id="" type="checkbox" value="www.chilquintas.cl.">
<input name="checkbox10_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=www.chilquintas.cl.&amp;rr_ttl=500&amp;rr_type=CNAME&amp;rr_data=dvpsdlqg629k8.cloudfront.net." id="" onmouseup="" title="" class="" onmousedown="" target="">
www.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
500
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
dvpsdlqg629k8.cloudf...
</td>
</tr>
<tr class="color2 " style="" id="row_11">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox11" id="" type="checkbox" value="rj7v6b4dsjua.chilquintas.cl.">
<input name="checkbox11_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=rj7v6b4dsjua.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=gv-tzjqklchqmasun.dv.googlehosted.com.chilquintas.cl." id="" onmouseup="" title="" class="" onmousedown="" target="">
rj7v6b4dsjua.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
gv-tzjqklchqmasun.dv...
</td>
</tr>
<tr class="color1 " style="" id="row_12">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox12" id="" type="checkbox" value="clienteslibres.chilquintas.cl.">
<input name="checkbox12_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=clienteslibres.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=d30vtn82s3xw64.cloudfront.net." id="" onmouseup="" title="" class="" onmousedown="" target="">
clienteslibres.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
d30vtn82s3xw64.cloud...
</td>
</tr>
<tr class="color2 " style="" id="row_13">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox13" id="" type="checkbox" value="autodiscover.chilquintas.cl.">
<input name="checkbox13_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=autodiscover.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=autodiscover.outlook.com." id="" onmouseup="" title="" class="" onmousedown="" target="">
autodiscover.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
autodiscover.outlook...
</td>
</tr>
<tr class="color1 " style="" id="row_14">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox14" id="" type="checkbox" value="selector2._domainkey.chilquintas.cl.">
<input name="checkbox14_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=selector2._domainkey.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=selector2-chilquintas-cl._domainkey.chilquintacl.e-v1.dkim.mail.microsoft." id="" onmouseup="" title="" class="" onmousedown="" target="">
selector2._domainkey.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
selector2-chilquinta...
</td>
</tr>
<tr class="color2 " style="" id="row_15">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox15" id="" type="checkbox" value="selector1._domainkey.chilquintas.cl.">
<input name="checkbox15_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=selector1._domainkey.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=selector1-chilquintas-cl._domainkey.chilquintacl.e-v1.dkim.mail.microsoft." id="" onmouseup="" title="" class="" onmousedown="" target="">
selector1._domainkey.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
selector1-chilquinta...
</td>
</tr>
<tr class="color1 " style="" id="row_16">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox16" id="" type="checkbox" value="60254983.chilquintas.cl.">
<input name="checkbox16_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=60254983.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=CNAME&amp;rr_data=google.com." id="" onmouseup="" title="" class="" onmousedown="" target="">
60254983.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
CNAME
</td>
<td class="last" align="left" style="">
google.com.
</td>
</tr>
<tr class="color2 " style="" id="row_17">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox17" id="" type="checkbox" value="wsmdms-proxy.chilquintas.cl.">
<input name="checkbox17_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=wsmdms-proxy.chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=A&amp;rr_data=200.72.40.117" id="" onmouseup="" title="" class="" onmousedown="" target="">
wsmdms-proxy.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
A
</td>
<td class="last" align="left" style="">
200.72.40.117
</td>
</tr>
<tr class="color1 " style="" id="row_18">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox18" id="" type="checkbox" value="tuclave.chilquintas.cl.">
<input name="checkbox18_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=tuclave.chilquintas.cl.&amp;rr_ttl=3600&amp;rr_type=A&amp;rr_data=200.31.52.121" id="" onmouseup="" title="" class="" onmousedown="" target="">
tuclave.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
3600
</td>
<td class="" align="left" style="">
A
</td>
<td class="last" align="left" style="">
200.31.52.121
</td>
</tr>
<tr class="color2 " style="" id="row_19">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox19" id="" type="checkbox" value="balanceo.chilquintas.cl.">
<input name="checkbox19_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=balanceo.chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=A&amp;rr_data=200.72.40.106" id="" onmouseup="" title="" class="" onmousedown="" target="">
balanceo.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
A
</td>
<td class="last" align="left" style="">
200.72.40.106
</td>
</tr>
<tr class="color1 " style="" id="row_20">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox20" id="" type="checkbox" value="balanceo.chilquintas.cl.">
<input name="checkbox20_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=balanceo.chilquintas.cl.&amp;rr_ttl=0&amp;rr_type=A&amp;rr_data=190.153.249.194" id="" onmouseup="" title="" class="" onmousedown="" target="">
balanceo.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
0
</td>
<td class="" align="left" style="">
A
</td>
<td class="last" align="left" style="">
190.153.249.194
</td>
</tr>
<tr class="color2 " style="" id="row_21">
<td class="first" align="left" style="">
              <input onclick="" partition="" name="checkbox21" id="" type="checkbox" value="app-ia.chilquintas.cl.">
<input name="checkbox21_before" type="hidden" value="unchecked">
</td>
<td class="" align="left" style="">
<a onmouseout="" onmouseover="" onclick="" href="/tmui/Control/jspmap/tmui/globallb/zfd/record/properties.jsp?&amp;view_name=external&amp;zone_name=chilquintas.cl.&amp;rr_name=app-ia.chilquintas.cl.&amp;rr_ttl=300&amp;rr_type=A&amp;rr_data=13.128.249.246" id="" onmouseup="" title="" class="" onmousedown="" target="">
app-ia.chilquintas.cl.</a>
</td>
<td class="" align="left" style="">
external
</td>
<td class="" align="left" style="">
chilquintas.cl.
</td>
<td class="" align="left" style="">
300
</td>
<td class="" align="left" style="">
A
</td>
<td class="last" align="left" style="">
13.128.249.246
</td>
</tr>
                        </tbody>
                    </table>
"""

# RegEx for parsing rows manually since we have the content
row_matches = re.findall(r'<tr.*?id="row_\d+">(.*?)</tr>', html_content, re.DOTALL)

records = []

for row_html in row_matches:
    td_matches = re.findall(r'<td.*?>(.*?)</td>', row_html, re.DOTALL)
    if len(td_matches) >= 7:
        # Extract name from link
        link_match = re.search(r'href="(.*?)".*?>(.*?)</a>', td_matches[1], re.DOTALL)
        if link_match:
            href = link_match.group(1).replace('&amp;', '&')
            name = link_match.group(2).strip()
            
            # Parse URL or extracting full RDATA from the link
            params = parse_qs(href.split('?')[-1])
            full_rdata = unquote(params.get('rr_data', [''])[0])
        else:
            name = td_matches[1].strip()
            full_rdata = ""
            
        view = td_matches[2].strip()
        zone = td_matches[3].strip()
        ttl = td_matches[4].strip()
        record_type = td_matches[5].strip()
        
        records.append({
            'Name': name,
            'View Name': view,
            'Zone Name': zone,
            'TTL': ttl,
            'Type': record_type,
            'RDATA': full_rdata
        })

# Sort by Name and Type
records.sort(key=lambda x: (x['Name'], x['Type']))

# Write to CSV
with open('/Users/claudio/Antigravity/dns_records.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=['Name', 'View Name', 'Zone Name', 'TTL', 'Type', 'RDATA'])
    writer.writeheader()
    writer.writerows(records)

print(f"Successfully extracted {len(records)} records.")
