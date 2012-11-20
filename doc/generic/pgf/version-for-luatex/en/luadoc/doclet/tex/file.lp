% This file has been generated from the lua sources using the specialized version of
% LuaDoc that is part of pgf.

\begin{luafiledescription}{<%=file_doc.shortname%>}
<%if file_doc.description then%><%=file_doc.description%><%end%>


<%if #file_doc.tables > 0 then%>
  <%for _, tab_name in ipairs(file_doc.tables) do%>
  <%if file_doc.tables[tab_name].library then%>
    <%=luadoc.doclet.tex.include("library.lp", { doc=doc, file_doc=file_doc, tab=file_doc.tables[tab_name] })%>
  <%elseif file_doc.tables[tab_name].section then%>
    <%=luadoc.doclet.tex.include("section.lp", { doc=doc, file_doc=file_doc, tab=file_doc.tables[tab_name] })%>  
  <%else%>
    <%=luadoc.doclet.tex.include("table.lp", { doc=doc, file_doc=file_doc, tab=file_doc.tables[tab_name] })%>
  <%end%>
  <%end%>
<%end%>


<%if #file_doc.declares > 0 then%>
  <%for _, func_name in ipairs(file_doc.declares) do%>
    <%=luadoc.doclet.tex.include("declare.lp", { doc=doc, file_doc=file_doc, declare=file_doc.declares[func_name] })%>
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
