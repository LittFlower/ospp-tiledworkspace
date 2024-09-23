// Copyright (C) 2023 JiDe Zhang <zccrs@live.com>.
// SPDX-License-Identifier: Apache-2.0 OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Waylib.Server

// 工作区的实现
// QtObject {
//     id: workspaceManager
//     property var workspacesById: new Map()
//     property alias nWorkspaces: layoutOrder.count
//     property var __: QtObject {
//         id: privt
//         property int workspaceIdCnt: { workspaceIdCnt = layoutOrder.count - 1 }
//     }
//     function createWs() {
//         layoutOrder.append({ wsid: ++privt.workspaceIdCnt, layout: "tiled" })
//     }
//     function destroyWs(id) {
//         console.log(`workspace id=${id} destroyed!`)
//         layoutOrder.remove(id)
//     }
//     function moveWs(from, to) {
//         layoutOrder.move(from, to, 1)
//     }
//     function setLayout(id, layout) {
//         for (let i = 0; i < layoutOrder.count; i++) {
//             if (layoutOrder.get(i).wsid === id) {
//                 layoutOrder.setProperty(i, "layout", layout)
//                 break
//             }
//             onObjectRemoved: function (obj) {
//                 let index = verticalLayout.panes.indexOf(obj)
//                 verticalLayout.panes.splice(index, 1)
//                 obj.doDestroy()
//                 updateLayout()
//             }
//         }
//     }
//     property ListModel layoutOrder: ListModel {
//         id: layoutOrder
//         objectName: "layoutOrder"
//         ListElement {
//             wsid: 0
//             layout: "tiled"
//         }
//     }
//     property ListModel allSurfaces: ListModel {
//         id: allSurfaces
//         objectName: "allSurfaces"
//         function removeIf(cond) {
//             for (let i = 0; i < this.count; i++) {
//                 if (cond(this.get(i))) {
//                     this.remove(i)
//                     return
//                 }
//             }
//         }
//     }
//     Component.onCompleted: {
//         createWs(), createWs()
//     }
// }



Item {
    id: root


// 4 种 layout --------------------------------------------------------------------------------------
    Item {
        id: slideLayout
        property var panes: [] // list
        property int spacing: 0 // 间距，暂时设置为 0

        Connections {
            target: Helper // sign
            // onResize: resizePane(activeSurfaceItem, size, direction)
            onSwapPane: swapPane(activeSurfaceItem, targetSurfaceItem)
            onRemovePane: removePane(surfaceItem)
            onSwitchVertical: switchLayout()
        }

        function addPane(surfaceItem) {
            panes.append(surfaceItem)
            surfaceItem.x = 0
            surfaceItem.y = 0
            surfaceItem.width = root.width
            surfaceItem.height = root.height
        }

        function removePane(surfaceItem) {
            let index = panes.indexOf(surfaceItem)
            panes.splice(index, 1)
            surfaceItem.shellSurface.close()
        }

        // function 切换焦点的函数？
    }


    Item { // 垂直布局
        id: verticalLayout

        property var panes: [] // list      
        property int spacing: 0 // 间距，暂时设置为 0
        property surfaceItem selectSurfaceItem1
        property surfaceItem selectSurfaceItem2

        Connections {
            target: Helper // sign
            onResizePane: resizePane(size, direction)
            onSwapPane: swapPane()
            onRemovePane: removePane()
            onChoosePane: choosePane(id)
            // onSwitchVertical: switchLayout()
        }

        function addPane(surfaceItem) {
            console.log(typeof surfaceItem)
            if (panes.length === 0) {
                surfaceItem.x = 0
                surfaceItem.y = 0
                surfaceItem.width = root.width
                surfaceItem.height = root.height
                panes.append(surfaceItem)
            } else {
                let scale = panes.length / (panes.length + 1)
                panes[0].y = 0
                panes[0].height *= scale

                for (let i = 1; i < panes.length; i++) {
                    panes[i].y = panes[i-1].y + panes[i-1].height
                    panes[i].height *= scale
                }
                surfaceItem.y = panes[panes.length - 1].y + panes[panes.length - 1].height
                surfaceItem.height = root.height * (1.0 - scale)
                panes.append(surfaceItem)
            }
        }

        function choosePane(id) {
            if (id === 1) {
                let activeSurfaceItem = Helper.activatedSurface
                let index = panes.indexOf(activeSurfaceItem)
                if (index === panes.length - 1) {
                    selectSurfaceItem1 = panes[0]
                } else {
                    selectSurfaceItem1 = panes[index+1]
                }
                Helper.activatedSurface = selectSurfaceItem1
            } else if (id === 2) {
                let activeSurfaceItem = Helper.activatedSurface
                let index = panes.indexOf(activeSurfaceItem)
                if (index === panes.length - 1) {
                    selectSurfaceItem2 = panes[0]
                } else {
                    selectSurfaceItem2 = panes[index+1]
                }
                Helper.activatedSurface = selectSurfaceItem2
            }
        }

        function removePane() {
            let surfaceItem = selectSurfaceItem1
            let index = panes.indexOf(surfaceItem)
            if (panes.length === 1) {
                panes.splice(index, 1)
                // surfaceItem.height = 0 // 移除 pane 时不需要修改 height 和 y
                surfaceItem.shellSurface.closeSurface()
            } else {
                let scale = panes.length / (panes.length - 1) // 放大系数
                panes.splice(index, 1)
                panes[0].y = 0
                panes[0].height *= scale 
                for (let i = 1; i < panes.length; i++) {
                    panes[i].y = panes[i-1].y + panes[i-1].height
                    panes[i].height *= scale
                }
                surfaceItem.shellSurface.closeSurface()
            }
        }
        // direction: 1=左 2=右 3=上 4=下
        function resizePane(size, direction) {
            let activeSurfaceItem = Helper.activeSurfaceItem
            let index = panes.indexOf(activeSurfaceItem)
            let delta = size / index
            if (direction === 3) {
                // 用上边线改变高度
                if (index === 0) {
                    // 第一个窗格
                    console.log("You cannot up more!")
                    return
                }
                // 第一个窗格
                panes[0].y = 0
                panes[0].height -= delta
                // 中间的窗格
                for (let i = 1; i < index; ++i) {
                    panes[i].y = panes[i-1].y + panes[i-1].height
                    panes[i].height -= delta
                }
                // 当前窗格
                activeSurfaceItem.y -= size
                activeSurfaceItem.height += size
            } else if (direction === 4) {
                // 用下边线改变高度
                let last = panes.length - 1
                if (index === last) {
                    // 最后一个窗格
                    console.log("You can down more!")
                    return
                }
                // 最后一个窗格
                panes[last].y += delta
                panes[last].height -= delta
                for (let i = last - 1; i > index; i--) {
                    panes[i].height -= delta 
                    panes[i].y = panes[i+1].y - panes[i].height
                }
                activeSurfaceItem.y = activeSurfaceItem.y // y 不变
                activeSurfaceItem.height += size
            }
        }

        function swapPane() {
            let activatedSurface = selectSurfaceItem1
            let targetSurfaceItem = selectSurfaceItem2
            let index1 = panes.indexOf(activeSurfaceItem)
            let index2 = panes.indexOf(targetSurfaceItem)
            let delta = activeSurfaceItem.height - targetSurfaceItem.height 
            // swap y
            let tempYPos = activeSurfaceItem.y
            activeSurfaceItem.y = targetSurfaceItem.y
            // swap height
            let tempHeight = activeSurfaceItem.height
            activeSurfaceItem.height = targetSurfaceItem.height
            for (let i = index1 + 1; i <= index2 - 1; i++) {
                // 中间的窗口只改变 yPos
                panes[i].y += delta
            }
            targetSurfaceItem.y = tempYPos
            targetSurfaceItem.height = tempHeight
            // [panes[index1], panes[index2]] = [panes[index2], panes[index1]]
        }
    }


    Item { // 水平布局
        id: horizontalLayout

        property var panes: [] // list
        property int spacing: 0 // 间距，暂时设置为 0

        Connections {
            target: Helper // sign
            onResizePane: resizePane(size, direction)
            onSwapPane: swapPane()
            onRemovePane: removePane()
            onChoosePane: choosePane(id)
            // onSwitchHorizontal: switchLayout()
        }

        function addPane(surfaceItem) {
            if (panes.length === 0) {
                surfaceItem.x = 0
                surfaceItem.y = 0
                surfaceItem.width = root.width
                surfaceItem.height = root.height
                panes.append(surfaceItem)
            } else {
                let scale = panes.length / (panes.length + 1)
                panes[0].x = 0
                panes[0].width *= scale
                for (let i = 1; i < panes.length; i++) {
                    panes[i].x = panes[i-1].x + panes[i-1].width
                    panes[i].width *= scale
                }
                surfaceItem.x = panes[panes.length - 1].x + panes[panes.length - 1].width
                surfaceItem.width = root.width * (1.0 - scale)
                panes.append(surfaceItem)
            }
        }

        function choosePane(id) {
            if (id === 1) {
                let activeSurfaceItem = Helper.activatedSurface
                let index = panes.indexOf(activeSurfaceItem)
                if (index === panes.length - 1) {
                    selectSurfaceItem1 = panes[0]
                } else {
                    selectSurfaceItem1 = panes[index+1]
                }
                Helper.activatedSurface = selectSurfaceItem1
            } else if (id === 2) {
                let activeSurfaceItem = Helper.activatedSurface
                let index = panes.indexOf(activeSurfaceItem)
                if (index === panes.length - 1) {
                    selectSurfaceItem2 = panes[0]
                } else {
                    selectSurfaceItem2 = panes[index+1]
                }
                Helper.activatedSurface = selectSurfaceItem2
            }
        }

        function removePane() {
            let surfaceItem = selectSurfaceItem1
            let index = panes.indexOf(surfaceItem)
            if (panes.length === 1) {
                panes.splice(index, 1)
                // surfaceItem.height = 0 // 移除 pane 时不需要修改 height 和 y
                surfaceItem.shellSurface.close()
            } else {
                let scale = panes.length / (panes.length - 1) // 放大系数
                panes.splice(index, 1)
                panes[0].x = 0
                panes[0].width *= scale 
                for (let i = 1; i < panes.length; i++) {
                    panes[i].x = panes[i-1].x + panes[i-1].width
                    panes[i].width *= scale
                }
                surfaceItem.shellSurface.close()
            }
        }
        // direction: 1=左 2=右 3=上 4=下
        function resizePane(size, direction) {
            let activeSurfaceItem = Helper.activatedSurface
            let index = panes.indexOf(activeSurfaceItem)
            let delta = size / index
            if (direction === 1) {
                // 用左边线改变宽度
                if (index === 0) {
                    // 第一个窗格
                    console.log("You cannot left more!")
                    return
                }
                panes[0].x = 0
                panes[0].width += delta
                for (let i = 1; i < index; ++i) {
                    panes[i].x = panes[i-1].x + panes[i-1].width
                    panes[i].width += delta
                }
                activeSurfaceItem.x += size
                activeSurfaceItem.width -= size
            } else if (direction === 2) {
                let last = panes.length - 1
                if (index === last) {
                    // 用右边线改变宽度
                    console.log("You can right more!")
                    return
                }
                panes[last].x += delta
                panes[last].width -= delta
                for (let i = last - 1; i > index; i--) {
                    panes[i].width -= delta 
                    panes[i].x = panes[i+1].x - panes[i].width
                }
                activeSurfaceItem.x = activeSurfaceItem.x // x 不变
                activeSurfaceItem.width += size
            }
        }

        function swapPane() {
            let activeSurfaceItem = selectSurfaceItem1
            let targetSurfaceItem = selectSurfaceItem2
            let index1 = panes.indexOf(activeSurfaceItem)
            let index2 = panes.indexOf(targetSurfaceItem)
            let delta = activeSurfaceItem.width - targetSurfaceItem.width
            // swap X
            let tempXPos = activeSurfaceItem.x
            activeSurfaceItem.x = targetSurfaceItem.x
            // swap width
            let tempWidth = activeSurfaceItem.width
            activeSurfaceItem.width = targetSurfaceItem.width
            for (let i = index1 + 1; i <= index2 - 1; i++) {
                // 中间的窗口只改变 xPos
                panes[i].x -= delta
            }
            targetSurfaceItem.x = tempXPos
            targetSurfaceItem.width = tempWidth
            // [panes[index1], panes[index2]] = [panes[index2], panes[index1]]
        }
    }

    Item { // Tall 布局
        id: tallLayout

        property var panes: [] // list
        property int spacing: 0 // 间距，暂时设置为 0



        Connections {
            target: Helper // sign
            onResizePane: resizePane(size, direction)
            onSwapPane: swapPane()
            onRemovePane: removePane()
            onChoosePane: choosePane(id)
            // onSwitchTall: switchLayout()
        }

        function addPane(surfaceItem) {
            if (panes.length === 0) {
                surfaceItem.x = 0
                surfaceItem.y = 0
                surfaceItem.width = root.width
                surfaceItem.height = root.height
                panes.append(surfaceItem)
            } else if (panes.length === 1) {
                panes[0].width = root.width / 2
                surfaceItem.x = panes[0].x + panes[0].width
                surfaceItem.width = root.width / 2
                panes.append(surfaceItem)
            } else {
                // 有两个以上的窗口，在右边分屏垂直，按照垂直布局处理
                let scale = panes.length / (panes.length + 1)
                panes[1].y = 0
                panes[1].height *= scale
                for (let i = 2; i < panes.length; i++) {
                    panes[i].y = panes[i-1].y + panes[i-1].height
                    panes[i].height *= scale
                }
                surfaceItem.y = panes[panes.length - 1].y + panes[panes.length - 1].height
                surfaceItem.height = root.height * (1.0 - scale)
                panes.append(surfaceItem)
            }
        }
        // direction: 1=左 2=右 3=上 4=下
        function resizePane(size, direction) {
            let activeSurfaceItem = Helper.activatedSurface
            let index = panes.indexOf(activeSurfaceItem)
            if (index === 0) { // 第一个窗格 在左边
                if (direction === 1) {
                    console.log("You cannot resize the first pane on left!")
                    return
                } else if (direction === 2) {
                    activeSurfaceItem.width += size
                    for (let i = 1; i < panes.length; i++) {
                        panes[i].x += size
                        panes[i].width -= size
                    }
                    return
                }
                return
            } else { // 在右边的窗格
                if (direction === 3 || direction === 4) {
                    let last = panes.length - 1
                    let delta = size / (panes.length - 1)
                    if (index === 1) {
                        // 在右边的第一个窗格
                        if (direction === 3) {
                            // 移动上边线以调整大小
                            console.log("You cannot resize the first pane on up!")
                            return
                        } else if (direction === 4) {
                            panes[0].height += size
                            for (let i = 1; i < panes.length; i++) {
                                panes[i].y = panes[i-1].y + panes[i-1].height
                                panes[i].height -= delta
                            }
                        }
                    } else if (index === last) {
                        // 在右边的最后一个窗格
                        if (direction === 4) {
                            console.log("You cannot resize the last pane on down!")
                            return
                        } else if (direction === 3) {
                            panes[last].height -= size
                            panes[last].y += size
                            for (let i = last - 1; i >= 0; i--) {
                                panes[i].height += delta
                                panes[i].y = panes[i+1].y - panes[i].height
                            }
                        }
                    } else if (index > 1 && index < last) {
                        // 在右边的中间窗格
                        if (direction === 3) {
                            // 用上边线调整大小
                            panes[1].height += delta
                            panes[1].y = 0
                            for (let i = 2; i < index; i++) {
                                panes[i].height += delta
                                panes[i].y = panes[i-1].y + panes[i-1].height
                            }
                            activeSurfaceItem.height -= size
                            activeSurfaceItem.y += size
                        } else if (direction === 4) {
                            // 用下边线调整大小
                            panes[last].height -= delta
                            panes[last].y += delta
                            for (let i = last - 1; i > index; i--) {
                                panes[i].height -= delta
                                panes[i].y = panes[i+1].y - panes[i].height
                            }
                            activeSurfaceItem.height += size
                        }
                    }   
                } else if (direction === 3) {
                    panes[0].width += size
                    for (let i = 1; i < panes.length; i++) {
                        panes[i].x += size
                        panes[i].width -= size
                    }
                } else if (direction === 4) {
                    console.log("You cannot resize the pane on right!")
                    return
                }
            } 
        }

        function removePane() {
            let surfaceItem = selectedPane1
            let index = panes.indexOf(surfaceItem)
            if (panes.length === 2) { // 如果只有两个 直接扬成最大的
                panes[1].x = 0
                panes[1].y = 0
                panes[1].width = root.width
                panes[1].height = root.height
                panes.splice(index, 1)
                surfaceItem.shellSurface.closeSurface()
            } else if (index === 0) { // 两个以上窗口，删除左边的pane
                let scale = (panes.length - 1) / (panes.length - 2)
                // panes[2].x = pane[1].x
                panes[2].y = pane[1].y
                // panes[2].width = pane[1].width
                panes[2].height = pane[1].height * scale
                panes[1].x = panes[0].x // panes[0].x === 0
                // panes[1].y = panes[0].y
                panes[1].width = panes[0].width
                panes[1].height = panes[0].height
                for (let i = 3; i < panes.length; ++i) {
                    panes[i].height *= scale
                    panes[i].y = panes[i-1].y + panes[i-1].height
                }
                panes.splice(index, 1)
                surfaceItem.shellSurface.closeSurface()
            } else { // 两个以上 pane，删除右边的 pane
                let scale = (panes.length - 1) / (panes.length - 2)
                panes.splice(index, 1)
                panes[1].y = 0
                panes[1].height *= scale
                for (let i = 2; i < panes.length; i++) {
                    panes[i].y = panes[i-1].y + panes[i-1].height
                    panes[i].height *= scale
                }
                surfaceItem.shellSurface.closeSurface()
            }
        }

        function swapPane() {
            let activatedSurface = selectSurfaceItem1
            let targetSurfaceItem = selectSurfaceItem2
            let index1 = panes.indexOf(activeSurfaceItem)
            let index2 = panes.indexOf(targetSurfaceItem)
            if (index1 === 0 || index2 === 0) {
                let tempXPos = activeSurfaceItem.x
                let tempYPos = activeSurfaceItem.y
                let tempWidth = activeSurfaceItem.width
                let tempHeight = activeSurfaceItem.height
                activeSurfaceItem.x = targetSurfaceItem.x
                activeSurfaceItem.y = targetSurfaceItem.y
                activeSurfaceItem.width = targetSurfaceItem.width
                activeSurfaceItem.height = targetSurfaceItem.height
                targetSurfaceItem.x = tempXPos
                targetSurfaceItem.y = tempYPos
                targetSurfaceItem.width = tempWidth
                targetSurfaceItem.height = tempHeight
                // [panes[index1], panes[index2]] = [panes[index2], panes[index1]]
            } else {
                let delta = activeSurfaceItem.height - targetSurfaceItem.height
                let tempYPos = activeSurfaceItem.y
                activeSurfaceItem.y = targetSurfaceItem.y
                let tempHeight = activeSurfaceItem.height
                activeSurfaceItem.height = targetSurfaceItem.height
                for (let i = index1 + 1; i <= index2 - 1; i++) {
                    panes[i].y -= delta
                }
                targetSurfaceItem.y = tempYPos
                targetSurfaceItem.height = tempHeight
                // [panes[index1], panes[index2]] = [panes[index2], panes[index1]]
            }
        }
    }
// --------------------------------------------------------------------------------------



    function getSurfaceItemFromWaylandSurface(surface) {
        let finder = function(props) {
            if (!props.waylandSurface)
                return false
            // surface is WToplevelSurface or WSurfce
            if (props.waylandSurface === surface || props.waylandSurface.surface === surface)
                return true
        }

        let toplevel = Helper.xdgShellCreator.getIf(toplevelComponent, finder)
        if (toplevel) {
            return {
                shell: toplevel,
                item: toplevel,
                type: "toplevel"
            }
        }

        let popup = Helper.xdgShellCreator.getIf(popupComponent, finder)
        if (popup) {
            return {
                shell: popup,
                item: popup.xdgSurface,
                type: "popup"
            }
        }

        let layer = Helper.layerShellCreator.getIf(layerComponent, finder)
        if (layer) {
            return {
                shell: layer,
                item: layer.surfaceItem,
                type: "layer"
            }
        }

        let xwayland = Helper.xwaylandCreator.getIf(xwaylandComponent, finder)
        if (xwayland) {
            return {
                shell: xwayland,
                item: xwayland,
                type: "xwayland"
            }
        }

        return null
    }


    verticalLayout { // default layout
        id: defaultLayout
        anchors.fill: parent

        // 创建 pane
        DynamicCreatorComponent {
            id: paneCreator
            creator: Helper.xdgShellCreator
            chooserRole: "type"
            chooserRoleValue: "toplevel"
            autoDestroy: false

            onObjectRemoved: function (obj) {
                obj.doDestroy()
            }

            // xdgSurface 是窗口本身
            xdgSurface {
                id: toplevelVerticalSurfaceItem
                resizeMode: SurfaceItem.SizeToSurface

                Component.onCompleted: {
                    console.log(typeof toplevelVerticalSurfaceItem)
                    addPane(toplevelVerticalSurfaceItem)
                }

                OutputLayoutItem {
                    anchors.fill: parent
                    layout: Helper.outputLayout

                    onEnterOutput: function(output) {
                        waylandSurface.surface.enterOutput(output)
                        Helper.onSurfaceEnterOutput(waylandSurface, toplevelSurfaceItem, output)
                    }
                    onLeaveOutput: function(output) {
                        waylandSurface.surface.leaveOutput(output)
                        Helper.onSurfaceLeaveOutput(waylandSurface, toplevelSurfaceItem, output)
                    }
                }

                TiledToplevelHelper {
                    id: helper
                    surface: toplevelSurfaceItem
                    waylandSurface: toplevelSurfaceItem.waylandSurface
                    creator: toplevelComponent
                }
            }
        }
    }

    // GridLayout {
    //     anchors.fill: parent
    //     columns: Math.floor(root.width / 1920 * 4)

    //     DynamicCreatorComponent {
    //         id: toplevelComponent
    //         creator: Helper.xdgShellCreator
    //         chooserRole: "type"
    //         chooserRoleValue: "toplevel"
    //         autoDestroy: false

    //         onObjectRemoved: function (obj) {
    //             obj.doDestroy()
    //         }

    //         XdgSurface {
    //             id: toplevelSurfaceItem

    //             property var doDestroy: helper.doDestroy

    //             resizeMode: SurfaceItem.SizeToSurface
    //             z: (waylandSurface && waylandSurface.isActivated) ? 1 : 0

    //             Layout.fillWidth: true
    //             Layout.fillHeight: true
    //             Layout.minimumWidth: Math.max(toplevelSurfaceItem.minimumSize.width, 100)
    //             Layout.minimumHeight: Math.max(toplevelSurfaceItem.minimumSize.height, 50)
    //             Layout.maximumWidth: toplevelSurfaceItem.maximumSize.width
    //             Layout.maximumHeight: toplevelSurfaceItem.maximumSize.height
    //             Layout.horizontalStretchFactor: 1
    //             Layout.verticalStretchFactor: 1

    //             OutputLayoutItem {
    //                 anchors.fill: parent
    //                 layout: Helper.outputLayout

    //                 onEnterOutput: function(output) {
    //                     waylandSurface.surface.enterOutput(output)
    //                     Helper.onSurfaceEnterOutput(waylandSurface, toplevelSurfaceItem, output)
    //                 }
    //                 onLeaveOutput: function(output) {
    //                     waylandSurface.surface.leaveOutput(output)
    //                     Helper.onSurfaceLeaveOutput(waylandSurface, toplevelSurfaceItem, output)
    //                 }
    //             }

    //             TiledToplevelHelper {
    //                 id: helper

    //                 surface: toplevelSurfaceItem
    //                 waylandSurface: toplevelSurfaceItem.waylandSurface
    //                 creator: toplevelComponent
    //             }
    //         }
    //     }

    //     DynamicCreatorComponent {
    //         id: popupComponent
    //         creator: Helper.xdgShellCreator
    //         chooserRole: "type"
    //         chooserRoleValue: "popup"

    //         Popup {
    //             id: popup

    //             required property WaylandXdgSurface waylandSurface
    //             property string type

    //             property alias xdgSurface: popupSurfaceItem
    //             property var parentItem: root.getSurfaceItemFromWaylandSurface(waylandSurface.parentSurface)

    //             parent: parentItem ? parentItem.item : root
    //             visible: parentItem && parentItem.item.effectiveVisible
    //                     && waylandSurface.surface.mapped && waylandSurface.WaylandSocket.rootSocket.enabled
    //             x: {
    //                 let retX = 0 // X coordinate relative to parent
    //                 let minX = 0
    //                 let maxX = root.width - xdgSurface.width
    //                 if (!parentItem) {
    //                     retX = popupSurfaceItem.implicitPosition.x
    //                     if (retX > maxX)
    //                         retX = maxX
    //                     if (retX < minX)
    //                         retX = minX
    //                 } else {
    //                     retX = popupSurfaceItem.implicitPosition.x / parentItem.item.surfaceSizeRatio + parentItem.item.contentItem.x
    //                     let parentX = parent.mapToItem(root, 0, 0).x
    //                     if (retX + parentX > maxX) {
    //                         if (parentItem.type === "popup")
    //                             retX = retX - xdgSurface.width - parent.width
    //                         else
    //                             retX = maxX - parentX
    //                     }
    //                     if (retX + parentX < minX)
    //                         retX = minX - parentX
    //                 }
    //                 return retX
    //             }
    //             y: {
    //                 let retY = 0 // Y coordinate relative to parent
    //                 let minY = 0
    //                 let maxY = root.height - xdgSurface.height
    //                 if (!parentItem) {
    //                     retY = popupSurfaceItem.implicitPosition.y
    //                     if (retY > maxY)
    //                         retY = maxY
    //                     if (retY < minY)
    //                         retY = minY
    //                 } else {
    //                     retY = popupSurfaceItem.implicitPosition.y / parentItem.item.surfaceSizeRatio + parentItem.item.contentItem.y
    //                     let parentY = parent.mapToItem(root, 0, 0).y
    //                     if (retY + parentY > maxY)
    //                         retY = maxY - parentY
    //                     if (retY + parentY < minY)
    //                         retY = minY - parentY
    //                 }
    //                 return retY
    //             }
    //             padding: 0
    //             background: null
    //             closePolicy: Popup.NoAutoClose

    //             XdgSurface {
    //                 id: popupSurfaceItem
    //                 waylandSurface: popup.waylandSurface

    //                 OutputLayoutItem {
    //                     anchors.fill: parent
    //                     layout: Helper.outputLayout

    //                     onEnterOutput: function(output) {
    //                         waylandSurface.surface.enterOutput(output)
    //                         Helper.onSurfaceEnterOutput(waylandSurface, popupSurfaceItem, output)
    //                     }
    //                     onLeaveOutput: function(output) {
    //                         waylandSurface.surface.leaveOutput(output)
    //                         Helper.onSurfaceLeaveOutput(waylandSurface, popupSurfaceItem, output)
    //                     }
    //                 }
    //             }
    //         }
    //     }

    //     DynamicCreatorComponent {
    //         id: xwaylandComponent
    //         creator: Helper.xwaylandCreator
    //         autoDestroy: false

    //         onObjectRemoved: function (obj) {
    //             obj.doDestroy()
    //         }

    //         XWaylandSurfaceItem {
    //             id: xwaylandSurfaceItem

    //             required property XWaylandSurface waylandSurface
    //             property var doDestroy: helper.doDestroy

    //             shellSurface: waylandSurface
    //             resizeMode: SurfaceItem.SizeToSurface
    //             // TODO: Support popup/menu
    //             positionMode: xwaylandSurfaceItem.effectiveVisible ? XWaylandSurfaceItem.PositionToSurface : XWaylandSurfaceItem.ManualPosition
    //             z: (waylandSurface && waylandSurface.isActivated) ? 1 : 0

    //             Layout.fillWidth: true
    //             Layout.fillHeight: true
    //             Layout.minimumWidth: Math.max(xwaylandSurfaceItem.minimumSize.width, 100)
    //             Layout.minimumHeight: Math.max(xwaylandSurfaceItem.minimumSize.height, 50)
    //             Layout.maximumWidth: xwaylandSurfaceItem.maximumSize.width
    //             Layout.maximumHeight: xwaylandSurfaceItem.maximumSize.height
    //             Layout.horizontalStretchFactor: 1
    //             Layout.verticalStretchFactor: 1

    //             OutputLayoutItem {
    //                 anchors.fill: parent
    //                 layout: Helper.outputLayout

    //                 onEnterOutput: function(output) {
    //                     if (xwaylandSurfaceItem.waylandSurface.surface)
    //                         xwaylandSurfaceItem.waylandSurface.surface.enterOutput(output);
    //                     Helper.onSurfaceEnterOutput(waylandSurface, xwaylandSurfaceItem, output)
    //                 }
    //                 onLeaveOutput: function(output) {
    //                     if (xwaylandSurfaceItem.waylandSurface.surface)
    //                         xwaylandSurfaceItem.waylandSurface.surface.leaveOutput(output);
    //                     Helper.onSurfaceLeaveOutput(waylandSurface, xwaylandSurfaceItem, output)
    //                 }
    //             }

    //             TiledToplevelHelper {
    //                 id: helper

    //                 surface: xwaylandSurfaceItem
    //                 waylandSurface: surface.waylandSurface
    //                 creator: xwaylandComponent
    //             }
    //         }
    //     }
    // }

    DynamicCreatorComponent {
        id: layerComponent
        creator: Helper.layerShellCreator
        autoDestroy: false

        onObjectRemoved: function (obj) {
            obj.doDestroy()
        }

        LayerSurface {
            id: layerSurface
            creator: layerComponent
        }
    }

    DynamicCreatorComponent {
        id: inputPopupComponent
        creator: Helper.inputPopupCreator

        InputPopupSurface {
            required property WaylandInputPopupSurface popupSurface

            parent: getSurfaceItemFromWaylandSurface(popupSurface.parentSurface)
            id: inputPopupSurface
            shellSurface: popupSurface
        }
    }
}
