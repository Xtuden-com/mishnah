xquery version "3.0";

module namespace app="http://www.digitalmishnah.org/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://www.digitalmishnah.org/config" at "config.xqm";

(:import module namespace console="http://exist-db.org/xquery/console";:)

declare namespace my="local-functions.uri";
declare namespace tei="http://www.tei-c.org/ns/1.0"; 

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute: data-template="app:test" or class="app:test" (deprecated). 
 : The function has to take 2 default parameters. Additional parameters are automatically mapped to
 : any matching request or function parameter.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

(:~
 : This templating function generates a TOC panel
 :
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:toc($node as node(), $model as map(*)) {
    (: TODO adjust this to send out a model to subtemplates :)
    let $input := doc(concat($config:data-root, "/mishnah/ref.xml"))
    let $step1 := transform:transform($input, doc("//exist/apps/digitalmishnah/xsl/index-wit-compos.xsl"), 
                    <parameters>
                       <param name="tei-loc" value="{$config:http-data-root}/mishnah/"/>
                    </parameters>)
    let $tract-compos := transform:transform($step1, doc("//exist/apps/digitalmishnah//xsl/groupFromIndex.xsl"), 
            <parameters>
               <param name="unit" value="all"/>
            </parameters>)
    let $index := doc(concat($config:data-root, "/mishnah/index.xml"))
    return
      for $order in $index//my:order
      return (
        <a href="#{$order/@n}" class="list-group-item" data-toggle="collapse">
           <i class="glyphicon glyphicon-chevron-right"></i> {string($order/@n)} 
        </a>,
        <div class="list-group collapse" id="{$order/@n}">{
            for $tract in $order/my:tract
            return
                if (substring-after($tract/@xml:id,'ref.') = $tract-compos//my:tract-compos/@n)
                then (
                    (: This tractate has chapter children :)
                    <a href="#{$tract/@n}" class="list-group-item" data-toggle="collapse">
                        <i class="glyphicon glyphicon-chevron-right"></i> {replace($tract/@n,'_',' ')}
                    </a>,
                    <div class="list-group collapse" id="{$tract/@n}">{
                       for $chap in $tract/my:chapter
                       return
                           (:if (substring-after($chap/@xml:id,'ref.') = $tract-compos//my:ch-compos/@n)
                           then
                               (\: This chapter has mishnah children :\)
                               <a href="#{substring-after($chap/@xml:id,'ref.')}" class="list-group-item" data-toggle="collapse">                                             
                                   Chapter {substring-after($chap/@xml:id, concat($chap/parent::my:tract/@xml:id, '.'))}
                                   {
                                   if (substring-after($chap/@xml:id,'ref.') = $tract-compos//my:ch-compos/@n)
                                   then 
                                       <div class="list-group collapse" id="{$chap/@xml:id}">{
                                           for $mish in $chap/my:mishnah
                                           return
                                               if (substring-after($mish/@xml:id,'ref.') = $tract-compos//my:m-compos/@n)
                                               then
                                                   (\: This Mishnah has text :\)
                                                   <a class="list-group-item" href="align?unit=m&amp;mcite={substring-after($mish/@xml:id,'ref.')}&amp;tractName={$mish/ancestor::my:tract/@n}">
                                                       {concat('Mishnah ',substring-after($mish/@xml:id, concat($mish/ancestor::my:tract/@xml:id, '.')))}
                                                   </a>
                                               else
                                                <a class="list-group-item">{concat('Mishnah ',substring-after($mish/@xml:id, concat($mish/ancestor::my:tract/@xml:id, '.')))}</a>
                                       }</div>
                                   else ()
                                   }
                               </a>
                           else:)
                               <a href="#{substring-after($chap/@xml:id,'ref.')}" class="list-group-item" id="ch_{replace(substring-after($chap/@xml:id,'ref.'), "\.", "_")}">
                                   Chapter {substring-after($chap/@xml:id, concat($chap/parent::my:tract/@xml:id, '.'))}
                               </a >
                    }</div>)
                 else 
                    <a class="list-group-item">{replace($tract/@n,'_',' ')}</a>
        }</div>)
};