% This file has been generated from the lua sources using the specialized version of
% LuaDoc that is part of pgf.

\begin{luafiledescription}{<%=file_doc.shortname%>}
<%if file_doc.description then%><%=file_doc.description%><%end%>


<%if #file_doc.tables > 0 then%>
  <%for _, tab_name in ipairs(file_doc.tables) do%>
    <%=luadoc.doclet.tex.include("table.lp", { doc=doc, file_doc=file_doc, tab=file_doc.tables[tab_name] })%>
  <%end%>
<%end%>


<%if #file_doc.functions > 0 then%>
  <%for _, func_name in ipairs(file_doc.functions) do%>
    <%if not file_doc.functions[func_name][ignore] then%>
      <%=luadoc.doclet.tex.include("function.lp", { doc=doc, file_doc=file_doc, func=file_doc.functions[func_name] })%>
    <%end%>
  <%end%>
<%end%>

\end{luafiledescription}
