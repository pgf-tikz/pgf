% This file has been generated from the lua sources using LuaDoc.
% To regenerate it call "make genluadoc" in
% doc/generic/pgf/version-for-luatex/en.

\paragraph{<%=file_doc.shortname%>}
<%if file_doc.description then%><%=file_doc.description%><%end%>

<%if #file_doc.functions > 0 then%><%for _, func_name in ipairs(file_doc.functions) do%><%if not file_doc.functions[func_name][ignore] then%><%=luadoc.doclet.tex.include("function.lp", { doc=doc, file_doc=file_doc, func=file_doc.functions[func_name] })%><%end%><%end%><%end%>
