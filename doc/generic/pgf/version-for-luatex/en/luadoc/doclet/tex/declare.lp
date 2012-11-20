<%if declare.info.type then%>
  \begin{luadeclare}{<%=declare.name:gsub('_', '\\_')%>}{<%if (not declare.param) or #declare.param==0 then%><%="\\meta{"..declare.info.type.."}"%><%else%><%for i, paramname in ipairs(declare.param or {}) do%><%="\\meta{"..paramname:gsub('_', '\\_').."}"%><%end%><%end%>}{<%=declare.info.default%>}{<%=declare.info.initial%>}
    <%=declare.info.key_summary%>
    <%=declare.description%>
    <%=declare.info.documentation%>
    <%if declare.info.examples then%>
    \par\smallskip \emph{Example<%=#declare.info.examples > 1 and 's' or ''%>:}
    <%end%>
    <%for _,e in ipairs(declare.info.examples or {}) do%>
\begin{codeexample}[]
<%=e%>
\end{codeexample}    
    <%end%>
  \end{luadeclare}
  <%else%>
\begin{luadeclarestyle}{<%=declare.name:gsub('_', '\\_')%>}{<%for i, paramname in ipairs(declare.param or {}) do%><%="\\meta{"..paramname:gsub('_', '\\_').."}"%><%end%>}{<%=declare.info.default%>}{<%=declare.info.initial%>}
    <%=declare.info.key_summary%>
    <%=declare.description%>
    <%=declare.info.documentation%>
    <%if declare.info.examples then%>
    \par\smallskip \emph{Example<%=#declare.info.examples > 1 and 's' or ''%>:}
    <%end%>
    <%for _,e in ipairs(declare.info.examples or {}) do%>
\begin{codeexample}[]
<%=e%>
\end{codeexample}    
    <%end%>
  \end{luadeclarestyle}
<%end%>