private import geometry;

real rayArrowSize = 1.5mm;
real arcArrowSize = 1mm;
real mirrorThickness = 1mm;
pen mirrorColor = gray(0.85);
pen mirrorNormalLine = (dashed*0.5);
pen mirrorOpticalAxisLine = dashdotted;
pen virtualRay = dashed;

/**
 * repräsentiert ein Paar von einer Gerade `line normalLine` einem Punkt `entry point` auf der Gerade.
 *
 */
struct PointLine {
    point p;
    line l;

    void operator init(point entry, line normalLine){
        this.p = entry;
        this.l = normalLine;
    }
};

/**
 * Ein ebene Spiegel ist charakteristik durch einen Punkt und einen Vertor als Normalvektor des Spiels.
 * Die Richtung des Normalsvektor zeigt die reflektierende Seite des Spiegels (von der Spiegelsebene weg).
 */
struct PlanaMirror {
    // conceptual properties
    /**
     * is oriented from mirror surface to outside.
     */
    vector normalDirection;
    /**
     * center point of the mirror
     */
    point center;
    /**
     * line defined by center point and normal direction.
     */
    line normalLine;
    /**
     * reflecting line of the mirror ("front side")
     */
    line surfaceLine;

    // properties for drawing:
    // private:
    private vector offsetP ;
    point mostLeft ;
    point leftOffset;
    point mostRight;
    point rightOffset;
    point normalFarthest;

    real normalLength;

    /**
     * create a PlanaMirror.
     * @param normalDirection direction of normal line
     * @param center the (default) entry point of the incomming ray
     */
    void operator init(vector normalDirection=(0, 1), point center = (0,0)) {
        this.normalDirection = normalDirection;
        this.center = center;
        this.normalLine = line(this.center, false, this.center+normalDirection);
        this.surfaceLine = perpendicular(this.center, this.normalDirection);        
    }


    /**
     * calculates the normal line by a given distance from center point of the mirror.
     * the vector in the instance of PointLine is oriented in the direction from the
     * mirror surface to outside.
     *
     * @param incidentPosition the position of the incident point on the mirror surface.
     * That is the distance from this point to the mirror center.
     */
    PointLine calculateNormal(real incidentPosition) {
        if(incidentPosition != 0) {
            point tmpEntry = curpoint(this.surfaceLine, incidentPosition);
            line tmpNorm = line(tmpEntry, tmpEntry + this.normalDirection);
            return PointLine(tmpEntry, tmpNorm);
        } else {
            return PointLine(this.center, this.normalLine);
        }
    }

    /**
     * calculate the entry point of a ray defined by source of light (point) and by a propagation direction (vector).
     * @param source source of the ray
     * @param direction propagation-direction of the ray
     * @return Normal Line at the entry point of this ray
     */
    PointLine calculateNormal(point source, vector direction) {
        line incidentRay = line(source, source + direction);
        point entryPoint = intersectionpoint(incidentRay, this.surfaceLine);
        line tmpNormal = line(entryPoint, entryPoint + this.normalDirection);
        return PointLine(entryPoint, tmpNormal);
    }

    /**
     * calculates the reflected point of a given source and the given normal line.
     * That is the point, which is symetrical to the source point with noral line as Ayis of Symetry.
     *
     * @param source source of line
     * @param nl normal line to the mirror surface
     *
     */
    point reflectedPoint(point source, PointLine nl){
        line tmpNorm = nl.l;
        transform tt = reflect(tmpNorm);
        return tt * source;
    }

    /**
     * calculate the reflected ray of a entry ray from given source to the (default) entry
     * point of this mirror
     */
    point reflectedPoint(point source, real incidentPosition=0) {
        PointLine nl = calculateNormal(incidentPosition);
        return this.reflectedPoint(source, nl);
    }

    /**
     * Image point of a given source point, that is the symetrical point of the source point
     * relativity to the mirror surface
     */
    point imagePoint(point source){
        transform m = reflect(this.surfaceLine);
        return m*source;
    }


    /**
     * setup size for mirror to make it draw-able
     * @param leftWidth distance from entry point to the left side of the mirror
     * @param rightWidth distance from entry point to the right side of the mirror
     * @param normalLength the length of the drawn part of the normal ray, measured from entry point
     *
     * @return this mirror
     */
    PlanaMirror setupMirrorSize(real leftWidth, real rightWidth=leftWidth, real normalLength=leftWidth, real thickness=mirrorThickness){
        // properties for drawing:
        this.offsetP = -thickness * unit(this.normalDirection);
        this.mostLeft = curpoint(this.surfaceLine, leftWidth);
        this.leftOffset = this.mostLeft + this.offsetP;

        this.mostRight = curpoint(this.surfaceLine, -rightWidth);
        this.rightOffset = this.mostRight + this.offsetP;

        this.normalLength = normalLength;
        this.normalFarthest = this.normalLength*unit(this.normalDirection);
        return this;
    }


    /**
     * draw the mirror accorded to its side
     */
    PlanaMirror drawMirror(bool withNormal=true, pen p=defaultpen) {
        segment mSurface = segment(mostLeft, mostRight);
        fill( mostLeft -- leftOffset -- rightOffset -- mostRight -- cycle, p + mirrorColor );
        draw( mSurface );
        if(withNormal) {
            segment mNormal = segment(this.center + offsetP, this.center);//
            draw( mNormal, p);

            segment trueNormal = segment(this.center, this.center + this.normalFarthest);
            draw( trueNormal, p + mirrorNormalLine );
        }
        return this;
    }

    /**
     * @param nl must be calculate before
     */
    PlanaMirror drawNormal(PointLine nl, real length=this.normalLength, pen p = defaultpen) {
        segment trueNormal = segment(nl.p, nl.p + length*unit(this.normalDirection));
        draw( trueNormal, p + mirrorNormalLine );
        return this;
    }

    /**
     * @param incidentPosition is used to calculate the normal line and the contact point on the surface of mirror
     * @param length the length of the normal segment
     */
    PlanaMirror drawNormal(real incidentPosition, real length=this.normalLength, pen p = defaultpen) {
        PointLine nl = this.calculateNormal(incidentPosition);
        return this.drawNormal(nl, length, p);
    }


    /**
     * @param source source of ray
     * @param nl must be calculated before
     * @param arrowPosition
     */
    PlanaMirror drawIncidentRay(point source, PointLine normalLine, real arrowPosition=0, pen p = defaultpen){
        line entryRay = line(source, false, normalLine.p, false);
        draw(
            entryRay,
            arrow=Arrow(rayArrowSize, position=arrowPosition),
            p = p
        );
        return this;
    }

    /**
     * @param source source of ray
     * @param incidentPosition defines the position (positive or negative) from the mirror center point
     * to the entry point.
     * @param arrowPosition defines the relativ position (in Interval [0,1]) of the arrow on the
     * incident ray. The arrow is placed by value 0 at the source, by value 1 at the entry point
     * @return this mirror
     */
    PlanaMirror drawIncidentRay(point source, real incidentPosition = 0.0, real arrowPosition=0, pen p = defaultpen){
        PointLine nl = this.calculateNormal(incidentPosition);
        return this.drawIncidentRay(source, nl, arrowPosition, p);
    }


    /**
     * @param source source of ray
     * @param nl must be calculated before
     */
    PlanaMirror drawReflectedRay(point source, PointLine normalLine, real arrowPosition=1, real rayLength=0, pen p = defaultpen){
        point target = this.reflectedPoint(source, normalLine);
        line ray = line(normalLine.p, false, target, true);
        if(rayLength > 0) {
            point target = curpoint(ray, rayLength);
            ray = line(normalLine.p, false, target, false);
        }
        draw(
            ray,
            arrow=Arrow(rayArrowSize, position=arrowPosition),
            p = p
        );
        return this;
    }

    /**
     * @param source ray source
     * @param incidentPosition where the ray from source touch the mirror surface
     * @param arrowPosition
     * @param rayLength
     */
    PlanaMirror drawReflectedRay(point source, real incidentPosition = 0.0, real arrowPosition=1, real rayLength=0, pen p = defaultpen) {
        PointLine nl = this.calculateNormal(incidentPosition);
        return this.drawReflectedRay(source, nl, arrowPosition, rayLength, p);
    }

    PlanaMirror drawImageSegment(PointLine normalLine, point imagePoint, pen p = defaultpen){
        segment s = segment(normalLine.p, imagePoint);
        draw( s, p + virtualRay);
        return this;
    }


    PlanaMirror labelMirror(Label surfaceL="\tLabel{Grenzfläche}", Label normalL="\tLabel{Normal}"){
        if( surfaceL.align.default) {
            label(surfaceL, this.mostLeft, align = N);
        } else {
            label(surfaceL, this.mostLeft);
        }
        if(normalL.align.default) {
            label(normalL, this.normalFarthest, align=N);
        } else {
            label(normalL, this.normalFarthest);
        }
        return this;
    }

    PlanaMirror labelRays(point source, Label incident, Label reflected=incident) {
        markangle(incident, this.normalDirection, this.center, source, arrow=Arrows(size=arcArrowSize) );
        if (reflected != null) {
            point target = this.reflectedPoint(source);
            markangle(reflected, target, this.center, this.normalDirection, arrow=Arrows(size=arcArrowSize) );
        }
        return this;
    }

};

/**
 * extends the segment AB in the direction B by a given factor
 * @param startPoint start point
 * @param endPoint end point
 * @param factor extended factor in direction end point
 */
segment extendSegment(point startPoint, point endPoint, real factor) {
    line l = line(startPoint, endPoint);
    point e = relpoint(l, factor);
    return segment(startPoint, e);
}

struct ConcaveMirror {

    // geometrische Merkmale
    /**
    * Vertex of the mirror (dt. Scheitelpunkt)
    */
    point mirrorVertex;

    /**
    * optical axis, normalized to 1 Unit length.
    */
    vector opticalAxis;

    /**
    * center of curvature
    */
    point center;

    /**
    * focus of mirror
    */
    real focus;

    /**
     * radius of mirror
     */
    real radius;

    point focusPoint;

    coordsys internCs;

    // gestalterrische Merkmale
    real upAngle;
    real downAngle;
    real thickness;
    //
    circle mirror;
    path mirrorArc;
    //
    real byParallel = 1.5;
    real byFocus = 1.5;
    real byCenter = 1.5;

    /**
     * ``
     */
    static using coordsysMakerFn = coordsys(point center, vector opticalAxis, real radius);
    static coordsysMakerFn mkInternalCs = new coordsys(point center, vector opticalAxis, real radius) {
        vector i = -radius * opticalAxis;
        return cartesiansystem(center, i, vector((-i.v.y, i.v.x)) );
    };

    /**
    * @param mvertex the vertex of the mirror
    * @param oaxis the optical axis of the mirror, is oriented from the reflective surface away.
    * @param focus the focus length of the mirror, must be positive
    */
    void operator init(point mirrorVertex, vector opticalAxis, real focus) {
        this.mirrorVertex = mirrorVertex;
        this.opticalAxis = unit(opticalAxis);
        this.focus = focus;
        this.radius = 2*focus;
        point tCenter = (this.radius * this.opticalAxis) + mirrorVertex;
        this.internCs = mkInternalCs(tCenter, this.opticalAxis, this.radius);
        this.center = point(this.internCs, tCenter/this.internCs);        
        this.focusPoint = point(this.internCs, (0.5,0));
    }

    /**
    * @param mvertex the vertex of the mirror
    * @param focus the focus point of the mirror
    */
    void operator init(point mirrorVertex, point mirrorFocus) {
        this.mirrorVertex = mirrorVertex;
        vector fullAxis = mirrorFocus-mirrorVertex;
        this.opticalAxis = unit(fullAxis);
        this.focus = length(fullAxis);
        this.radius = 2*focus;
        point tCenter = (this.radius * this.opticalAxis) + mirrorVertex;
        this.internCs = mkInternalCs(tCenter, this.opticalAxis, this.radius);
        this.center = point(this.internCs, tCenter/this.internCs);
        this.focusPoint = point(this.internCs, (0.5,0));
    }

    /**
     * per default symetrical over optical axis
     */
    ConcaveMirror setupMirrorSize(real upAngle, real downAngle=upAngle, real thickness = mirrorThickness) {
        this.upAngle = upAngle;
        this.downAngle = downAngle;
        this.thickness = thickness;
        // compute mirror geometry
        this.mirror = circle(this.center, this.radius);
        this.mirrorArc = arcfromfocus(mirror, 180-this.downAngle, 180+this.upAngle);
        // there is a bug in geometry.asy, which does not allow to use arccircle and arc with
        // a coordinate system other than defaultcoordsys
        return this;
    }

    ConcaveMirror drawMirror(pen p=defaultpen) {
        draw(mirrorArc, p = p);
        line oAxis = Ox(this.center.coordsys);
        draw(oAxis, p = p + mirrorOpticalAxisLine);
        // show("",this.internCs);
        return this;
    }

    /**
     * @param byParallel extending factor of the reflexted ray from a pararellel ray
     * @param byFocus extending factor of the reflexted ray from a ray through focus
     * @param byCenter extending factor of the reflexted ray from a ray through center of curvature (of the mirror)
     */
    ConcaveMirror setupRaysExtend(real byParallel=1.8, real byFocus=byParallel, real byCenter=byFocus) {
        this.byParallel = byParallel;
        this.byFocus = byFocus;
        this.byCenter = byCenter;

        return this;
    }

    /**
     * calculates a pair of Point and Line.
     * The line is the incident ray from source and paralle to the optical axis of the mirror.
     * The point is the entry point of the incident ray on the mirror.
     */
    PointLine calculateIntersectionPointFromParalleRay(point nSource){
        line paralleIncident = line(nSource, point(this.internCs, (0, nSource.y)) );
        // draw(this.mirror, p = defaultpen + mirrorColor);
        point[] paralleEntry = intersectionpoints(paralleIncident, this.mirror);
        for(point e : paralleEntry ){
            //dot("", e);
            //write(e.x, e.y);
            if(e.x >= 0) {
                return PointLine(e, paralleIncident);
            }
        }
        write("ERROR: cannot find intersection point of the parallel ray with the mirror.");
        return PointLine(paralleEntry[0], paralleIncident);
    }

    /**
     * calculates a pair of Point and Line.
     * The line is the reflected ray of the ray through nSource and the focus point of the mirror.
     * The point is the entry point of the incident ray on the mirror.
     */
    PointLine calculateIntersectionPointFromFocusRay(point nSource){
        line focusRay = line(nSource, this.focusPoint);
        point[] entry = intersectionpoints(focusRay, this.mirror);
        for(point e : entry){
            // dot("", e);
            // write(e.x, e.y);
            if(e.x >= 0){
                line reflected = line(e, false, point(this.internCs, (0, e.y)), true );
                return PointLine(e, reflected);
            }
        }
        write("ERROR: cannot find intersection point of the focus ray with the mirror.");
        return PointLine(entry[0], focusRay);
    }

    point calculateIntersectionPointFromCenterRay(point nSource, point imgPoint){
        line centerRay = line(nSource, imgPoint);
        //draw(centerRay);
        point[] entry = intersectionpoints(centerRay, this.mirror);
        for(point e : entry){
            // dot("", e);
            // write(e.x, e.y);
            if(e.x >= 0){
                //write("calculated point: ", e.x, e.y);
                //line check = line(e, nSource);
                //draw(check);
                return e;
            }
        }
        write("ERROR: cannot find intersection point of the center ray with the mirror.");
        return point(this.internCs, (0, 0) );
    }

    private void drawRealImageInside(point nSource, pen p) {
        // determine the reflex ray from the parallel ray;
        PointLine paralle = calculateIntersectionPointFromParalleRay(nSource);
        point entryPoint = paralle.p;
        line paralenRay = line(nSource, false, entryPoint, false);
        draw(paralenRay, p = p);
        // determine the reflex ray from the parallel ray;
        PointLine focusRay = calculateIntersectionPointFromFocusRay(nSource);
        line sourceFocusRay = line(nSource, false, focusRay.p, false);
        draw(sourceFocusRay, p = p);
        // find out the image point
        point imgPoint = intersectionpoint( line(paralle.p, this.focusPoint), focusRay.l);
        dot(imgPoint);
        // draw the reflexted rays as segments
        segment reflexFocus = extendSegment(paralle.p, imgPoint, this.byParallel);
        draw(reflexFocus, p = p, arrow = Arrow(rayArrowSize));
        segment reflexParallel = extendSegment(focusRay.p, imgPoint, this.byFocus);
        draw(reflexParallel, p = p, arrow=Arrow(rayArrowSize));
        // FAKE ray through the center cause of approximate by sphrecial mirror
        point reflectedByCenter = calculateIntersectionPointFromCenterRay(nSource, imgPoint);
        segment incidentRayThroughCenter = segment(nSource, reflectedByCenter);
        draw(incidentRayThroughCenter, p = p);
        segment reflextedRayThrowCenter = extendSegment(reflectedByCenter, imgPoint, this.byCenter);
        draw(reflextedRayThrowCenter, p = p, arrow = Arrow(rayArrowSize));
    }

    private void drawRealImageOutside(point nSource, pen p) {
        write("drawRealImageOutside");
    }

    private void drawVirtualImage(point nSource, pen p){
        write("drawVirtualImage");
    }

    private void drawImageAtCenter(point nSource, pen p) {
        write("drawImageAtCenter");
    }

    ConcaveMirror drawImage(point source, pen p=defaultpen) {
        point nSource = changecoordsys(this.internCs, source); //point(this.internCs, source/this.internCs);
        real x = nSource.x;
        if (x < 0) {
            drawRealImageInside(nSource, p);
        }else if (x > 0 && x < 0.5) {
            drawRealImageOutside(nSource, p);
        }else if(x > 0.5 && x < 1) {
            drawVirtualImage(nSource, p);
        }else if(x == 0) {
            drawImageAtCenter(nSource, p);
        }else if (x >= 1) {
            write("WARN: source of light behind mirror");
        }
        return this;
    }

    ConcaveMirror labelMirrorPoint(Label centerL="$C$", Label focusL="$F$", Label vertexL="$V$"){
        label(centerL, this.center);
        label(focusL, this.center -- this.mirrorVertex);
        label(vertexL, this.mirrorVertex);
        return this;
    }

    ConcaveMirror labelMirrorSize() {
        write("TODO");
        return this;
    }
};












