#
#       (c) Copyright 2014, Blue J Software - www.bluejs.com
#
#       MIT License (http://www.opensource.org/licenses/mit-license.php)
#
#       Permission is hereby granted, free of charge, to any person
#       obtaining a copy of this software and associated documentation
#       files (the "Software"), to deal in the Software without restriction,
#       including without limitation the rights to use, copy, modify, merge,
#       publish, distribute, sublicense, and/or sell copies of the Software,
#       and to permit persons to whom the Software is furnished to do so,
#       subject to the following conditions:
#
#       The above copyright notice and this permission notice shall be
#       included in all copies or substantial portions of the Software.
#
#       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#       OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
#       BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
#       ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#       CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#       THE SOFTWARE.


IMPORT util
IMPORT FGL lib_error
IMPORT FGL lib_ui

IMPORT FGL lib_settings

IMPORT FGL fglsvgcanvas
SCHEMA pool_doctors


PUBLIC TYPE gaugeType RECORD
    x, y INTEGER,
    r1, r2 INTEGER,
    min_value, max_value FLOAT,
    arc_start, arc_end FLOAT,
    title RECORD
        text STRING,
        x, y INTEGER
    END RECORD,
    value RECORD
        text STRING,
        x, y INTEGER
    END RECORD,
    major_ticks RECORD
        number INTEGER,
        depth FLOAT
    END RECORD,
    minor_ticks RECORD
        number INTEGER,
        depth FLOAT
    END RECORD,
    band DYNAMIC ARRAY OF RECORD
        min, max FLOAT,
        depth1, depth2 FLOAT,
        fill_color STRING
    END RECORD
END RECORD


PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION show(l_cm_code, l_cm_name)
define l_cm_code like customer.cm_code
define l_cm_name like customer.cm_name


    DEFINE g gaugeType

    DEFINE i, j INTEGER
    DEFINE a, a1, a2 FLOAT



    DEFINE root_svg, child_node om.DomNode
    DEFINE canvas_id INTEGER
    OPEN WINDOW w WITH FORM "customer_reading" ATTRIBUTES(TEXT="Reading")

    INITIALIZE g.* TO NULL
    LET g.x = 500
    LET g.y = 500
    LET g.r1 = 400
    LET g.r2 = 320
    LET g.arc_start = 225
    LET g.arc_end = 495

    LET g.title.text = "Temperature (C)"
    LET g.title.x = 500
    LET g.title.y = 75

    LET g.min_value = 25
    LET g.max_value = 30

    LET g.value.text = 26.8  -- TODO - From Web service
    LET g.value.x = 500
    LET g.value.y = 680

    LET g.major_ticks.number = 11


    LET g.minor_ticks.number = 4


    LET g.band[1].min = 25
    LET g.band[1].max = 25.5
    LET g.band[1].depth1 = 0.8
    LET g.band[1].depth2 = 1.0
    LET g.band[1].fill_color = "red"

    LET g.band[2].min = 25.5
    LET g.band[2].max = 26.5
    LET g.band[2].depth1 = 0.8
    LET g.band[2].depth2 = 1.0
    LET g.band[2].fill_color = "orange"

    LET g.band[3].min = 26.5
    LET g.band[3].max = 28.5
    LET g.band[3].depth1 = 0.8
    LET g.band[3].depth2 = 1.0
    LET g.band[3].fill_color= "green"

    LET g.band[4].min = 28.5
    LET g.band[4].max = 29.5
    LET g.band[4].depth1 = 0.8
    LET g.band[4].depth2 = 1.0
    LET g.band[4].fill_color = "orange"

    LET g.band[5].min = 29.5
    LET g.band[5].max = 30.0
    LET g.band[5].depth1 = 0.8
    LET g.band[5].depth2 = 1.0
    LET g.band[5].fill_color= "red"

    CALL fglsvgcanvas.initialize()

    LET canvas_id = fglsvgcanvas.create("formonly.wc_reading")
    LET root_svg =
        fglsvgcanvas.setRootSVGAttributes(
                NULL, NULL, NULL, -- viewport
                "0 0 1000 1000", -- viewbox
                "xMidYMid meet" -- preserveAspectRatio
            )

    -- Draw Border
    LET child_node = fglsvgcanvas.circle(g.x, g.y, g.r1)
    CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:white')
    CALL root_svg.appendChild(child_node)
   

    -- Draw Arc
    LET child_node = fglsvgcanvas.path(path_4_arc(g.x, g.y, g.r2, g.r2, g.arc_start, g.arc_end))
    CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:white')
    CALL root_svg.appendChild(child_node)


    -- Draw Colour Band
    FOR i = 1 TO g.band.getLength()
        LET a1 = g.arc_start + (g.arc_end - g.arc_start) * g.band[i].min / (g.max_value - g.min_value)
        LET a2 = g.arc_start + (g.arc_end - g.arc_start) * g.band[i].max / (g.max_value - g.min_value)

        LET child_node = fglsvgcanvas.path(
                    path_4_donut(
                        g.x, g.y, g.band[i].depth1 * g.r2, g.band[i].depth1 * g.r2, g.band[i].depth2 * g.r2,
                        g.band[i].depth2 * g.r2, a1, a2))
        CALL child_node.setAttribute(SVGATT_STYLE, SFMT('stroke:black;fill:%1', g.band[i].fill_color))
        CALL root_svg.appendChild(child_node)

    END FOR

    -- Draw Major Ticks
    FOR i = 1 TO g.major_ticks.number
        LET a = g.arc_start + (g.arc_end - g.arc_start) * (i - 1) / (g.major_ticks.number - 1)
        LET a = a * util.Math.pi() / 180

        LET child_node =
            fglsvgcanvas.line(
                g.x + 0.8 * g.r2 * util.Math.sin(a), g.y + 0.8 * g.r2 * -util.Math.cos(a), g.x + g.r2 * util.Math.sin(a),
                g.y + g.r2 * -util.Math.cos(a))
        CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:black')
        CALL root_svg.appendChild(child_node)

        IF i < g.major_ticks.number THEN
            FOR j = 1 TO g.minor_ticks.number
                LET a =
                    g.arc_start
                        + (g.arc_end - g.arc_start) * ((i - 1) * (g.minor_ticks.number + 1) + j)
                            / ((g.major_ticks.number - 1) * (g.minor_ticks.number + 1))
                LET a = a * util.Math.pi() / 180
                LET child_node =
                    fglsvgcanvas.line(
                        g.x + 0.9 * g.r2 * util.Math.sin(a), g.y + 0.9 * g.r2 * -util.Math.cos(a), g.x + g.r2 * util.Math.sin(a),
                        g.y + g.r2 * -util.Math.cos(a))
                CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:black')
                CALL root_svg.appendChild(child_node)

            END FOR
        END IF
    END FOR

    -- Draw Title
    IF g.title.text IS NOT NULL THEN
        LET child_node = fglsvgcanvas.text(g.title.x, g.title.y, g.title.text, "")
        CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:black')
        CALL child_node.setAttribute("text-anchor","middle")
        CALL child_node.setAttribute("font-size", 48)
        CALL root_svg.appendChild(child_node)
    END IF

    -- Draw Value
    IF g.value.text IS NOT NULL THEN
        LET child_node = fglsvgcanvas.text(g.value.x, g.value.y, g.value.text, "")
        CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:black')
        CALL child_node.setAttribute("text-anchor","middle")
        CALL child_node.setAttribute("font-size", 48)
        CALL root_svg.appendChild(child_node)
    END IF

    -- Draw Center

    -- Draw Needle
    LET a = g.arc_start + (g.arc_end - g.arc_start) * g.value.text / (g.max_value - g.min_value)
    LET a = a * util.Math.pi() / 180

    LET child_node = fglsvgcanvas.line(g.x, g.y, g.x + g.r2 * util.Math.cos(a), g.y + g.r2 * util.Math.sin(a))
    CALL child_node.setAttribute(SVGATT_STYLE, 'stroke:black;fill:black')
    CALL root_svg.appendChild(child_node)

    CALL fglsvgcanvas.display(canvas_id)

    MENU ""
       
        ON ACTION cancel
            EXIT MENU

        ON ACTION close
            EXIT MENU
    END MENU
    CLOSE WINDOW w

    CALL fglsvgcanvas.destroy(canvas_id)

    CALL fglsvgcanvas.finalize()

END FUNCTION

FUNCTION path_4_arc(cx, cy, rx, ry, a1, a2)
    DEFINE cx, cy, rx, ry INTEGER
    DEFINE a1, a2 FLOAT

    DEFINE d STRING
    DEFINE x1, y1, x2, y2 FLOAT

    #M x,y L x,y Arx,ry 0 0,1  "Z"
    LET x1 = cx + rx * util.Math.cos(util.Math.pi() * a1 / 180)
    LET y1 = cy + ry * util.Math.sin(util.Math.pi() * a1 / 180)

    LET x2 = cx + rx * util.Math.cos(util.Math.pi() * a2 / 180)
    LET y2 = cy + ry * util.Math.sin(util.Math.pi() * a2 / 180)
    LET d = SFMT("M%3,%4 A%5,%6 0 %9,1 %7,%8", cx, cy, x1, y1, rx, ry, x2, y2, IIF((a2 - a1) > 180, 1, 0))

    RETURN d

END FUNCTION

PRIVATE FUNCTION path_4_donut(cx, cy, rx1, ry1, rx2, ry2, a1, a2)

    DEFINE cx, cy, rx1, ry1, rx2, ry2 INTEGER
    DEFINE a1, a2 FLOAT

    DEFINE d STRING
    DEFINE x1, y1, x2, y2, x3, y3, x4, y4 FLOAT

    LET x1 = cx + rx1 * util.Math.cos(util.Math.pi() * a1 / 180)
    LET y1 = cy + ry1 * util.Math.sin(util.Math.pi() * a1 / 180)

    LET x2 = cx + rx1 * util.Math.cos(util.Math.pi() * a2 / 180)
    LET y2 = cy + ry1 * util.Math.sin(util.Math.pi() * a2 / 180)

    LET x3 = cx + rx2 * util.Math.cos(util.Math.pi() * a2 / 180)
    LET y3 = cy + ry2 * util.Math.sin(util.Math.pi() * a2 / 180)

    LET x4 = cx + rx2 * util.Math.cos(util.Math.pi() * a1 / 180)
    LET y4 = cy + ry2 * util.Math.sin(util.Math.pi() * a1 / 180)

    LET d =
        SFMT("M%7,%8 L%1,%2 A%9,%10 0 %13,1 %3,%4 L%5,%6 A%11,%12 0 %13,0 %7,%8",
            x1, y1, x2, y2, x3, y3, x4, y4, rx1, ry1, rx2, ry2, IIF((a2 - a1) > 180, 1, 0))

    RETURN d
END FUNCTION

{
From the web service, an indicator of what values will be received
    LET l_pool_data.temperature = 26.0 + (util.Math.rand(20) / 10)  26.0-28.0
    LET l_pool_data.hardness = 100.0 + (util.Math.rand(2000) / 10) 100-300
    LET l_pool_data.free_chlorine = 0.5 + (util.Math.rand(30) / 10) .5 - 3.5
    LET l_pool_data.total_chroline = 0.5 + (util.Math.rand(30) / 10) .5 - 3.5
    LET l_pool_data.total_alkalinity = 60.0 + (util.Math.rand(900) / 10)  60 - 150
    LET l_pool_data.ph = 7 + (util.Math.rand(10) / 10)   7-8
}
